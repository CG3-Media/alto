module Alto
  class Comment < ApplicationRecord
    include ::Alto::Subscribable
    include ::Alto::ImageAttachable

    belongs_to :ticket
    belongs_to :user, polymorphic: true
    belongs_to :parent, class_name: "Alto::Comment", optional: true
    has_many :replies, class_name: "Alto::Comment", foreign_key: "parent_id", dependent: :destroy
    has_many :upvotes, as: :upvotable, dependent: :destroy

    validates :content, presence: true
    validates :user_id, presence: true
    validates :depth, presence: true, numericality: { greater_than_or_equal_to: 0, less_than: 3 }
    validate :parent_must_be_from_same_ticket, if: :parent_id?
    validate :depth_must_be_parent_depth_plus_one, if: :parent_id?

    before_validation :set_depth
    # Set user_type for polymorphic association
    before_validation :set_user_type, if: -> { user_id.present? && user_type.blank? }

    # Host app callback hooks
    after_create :trigger_comment_created_callback
    after_destroy :trigger_comment_deleted_callback

    scope :recent, -> { order(created_at: :desc) }
    scope :popular, -> { left_joins(:upvotes).group(:id).order("count(alto_upvotes.id) desc") }
    scope :top_level, -> { where(parent_id: nil) }
    scope :threaded, -> { order(:created_at) }

    def upvoted_by?(user)
      return false unless user
      upvotes.exists?(user_id: user.id)
    end

    def upvotes_count
      upvotes.count
    end

    def can_be_voted_on?
      !ticket.locked?
    end

    def can_be_replied_to?
      depth < 2 && !ticket.locked? # Limit to 3 levels deep (0, 1, 2)
    end

    def is_reply?
      parent_id.present?
    end

    def thread_root
      return self unless parent_id?
      parent.thread_root
    end

    # Get all comments in a threaded structure for display
    def self.threaded_for_ticket(ticket)
      comments = ticket.comments.includes(:parent, :replies, :upvotes).threaded

      # Include image attachments if enabled
      if ::Alto.configuration.image_uploads_enabled && defined?(ActiveStorage)
        comments = comments.with_attached_images
      end

      # Build threaded structure: top-level comments with their nested replies
      top_level = comments.select { |c| c.parent_id.nil? }

      top_level.map do |comment|
        {
          comment: comment,
          replies: build_reply_tree(comment, comments)
        }
      end
    end

    # Subscribable concern implementation
    def subscribable_ticket
      ticket
    end

    def user_email
      ::Alto.configuration.user_email.call(user_id)
    end

    private

    def set_depth
      if parent_id?
        self.depth = parent.depth + 1
      else
        self.depth = 0
      end
    end

    def parent_must_be_from_same_ticket
      if parent && parent.ticket_id != ticket_id
        errors.add(:parent, "must be from the same ticket")
      end
    end

    def depth_must_be_parent_depth_plus_one
      if parent && depth != parent.depth + 1
        errors.add(:depth, "must be one level deeper than parent comment")
      end
    end

    def self.build_reply_tree(parent_comment, all_comments)
      replies = all_comments.select { |c| c.parent_id == parent_comment.id }

      replies.map do |reply|
        {
          comment: reply,
          replies: build_reply_tree(reply, all_comments)
        }
      end
    end

    def trigger_comment_created_callback
      ::Alto::CallbackManager.call(:comment_created, self, ticket, ticket.board, get_user_object(user_id))
    end

    def trigger_comment_deleted_callback
      ::Alto::CallbackManager.call(:comment_deleted, self, ticket, ticket.board, get_user_object(user_id))
    end

    def get_user_object(user_id)
      return nil unless user_id

      user_class = ::Alto.configuration.user_model.constantize rescue nil
      return nil unless user_class

      user_class.find_by(id: user_id)
    end

    def set_user_type
      self.user_type = ::Alto.configuration.user_model if user_id.present?
    end
  end
end
