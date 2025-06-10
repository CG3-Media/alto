module Alto
  class Ticket < ApplicationRecord
    include ::Alto::Subscribable

    belongs_to :board
    belongs_to :user, polymorphic: true
    has_many :comments, dependent: :destroy
    has_many :upvotes, as: :upvotable, dependent: :destroy
    has_many :subscriptions, class_name: 'Alto::Subscription', dependent: :destroy

    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true
    validates :user_id, presence: true
    validates :board_id, presence: true
    validate :status_slug_valid_for_board

    # Host app callback hooks
    after_create :trigger_ticket_created_callback
    after_update :trigger_ticket_status_changed_callback, if: :saved_change_to_status_slug?

    # Set default status when ticket is created
    before_create :set_default_status
    # Set user_type for polymorphic association
    before_validation :set_user_type, if: -> { user_id.present? && user_type.blank? }

    scope :by_status, ->(status_slug) { where(status_slug: status_slug) }
    scope :unlocked, -> { where(locked: false) }
    scope :locked, -> { where(locked: true) }
    scope :recent, -> { order(created_at: :desc) }
    scope :popular, -> { left_joins(:upvotes).group(:id).order('count(alto_upvotes.id) desc') }
    scope :for_board, ->(board) { where(board: board) }

        # Search scopes
    scope :search_by_content, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"
      # Use ILIKE for PostgreSQL, LIKE for others (case-insensitive search)
      if connection.adapter_name.downcase.include?('postgresql')
        where("title ILIKE ? OR description ILIKE ?", sanitized_query, sanitized_query)
      else
        where("LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", sanitized_query, sanitized_query)
      end
    }

    scope :search_by_comments, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"
      if connection.adapter_name.downcase.include?('postgresql')
        joins(:comments).where("alto_comments.content ILIKE ?", sanitized_query)
      else
        joins(:comments).where("LOWER(alto_comments.content) LIKE LOWER(?)", sanitized_query)
      end
    }

        scope :search, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"

      # Combined search in tickets OR comments with a single query
      if connection.adapter_name.downcase.include?('postgresql')
        left_joins(:comments).where(
          "(alto_tickets.title ILIKE ? OR alto_tickets.description ILIKE ?) OR alto_comments.content ILIKE ?",
          sanitized_query, sanitized_query, sanitized_query
        ).distinct
      else
        left_joins(:comments).where(
          "(LOWER(alto_tickets.title) LIKE LOWER(?) OR LOWER(alto_tickets.description) LIKE LOWER(?)) OR LOWER(alto_comments.content) LIKE LOWER(?)",
          sanitized_query, sanitized_query, sanitized_query
        ).distinct
      end
    }

    def upvoted_by?(user)
      return false unless user
      upvotes.exists?(user_id: user.id)
    end

    def upvotes_count
      upvotes.count
    end

    def can_be_voted_on?
      !locked?
    end

    def can_be_commented_on?
      !locked?
    end

    def locked?
      locked
    end

    # Status-related methods
    def status
      return nil unless board.has_status_tracking?
      board.status_by_slug(status_slug)
    end

    def status_name
      status&.name || status_slug&.humanize || 'Unknown'
    end

    def status_color_classes
      status&.color_classes || 'bg-gray-100 text-gray-800'
    end

    def available_statuses
      board.available_statuses
    end

    def can_change_status?
      board.has_status_tracking?
    end

    # Subscribable concern implementation
    def subscribable_ticket
      self
    end

    def user_email
      ::Alto.configuration.user_email.call(user_id)
    end

    private

    def trigger_ticket_created_callback
      ::Alto::CallbackManager.call(:ticket_created, self, board, get_user_object(user_id))
    end

    def trigger_ticket_status_changed_callback
      old_status_slug = saved_changes['status_slug'][0]
      new_status_slug = saved_changes['status_slug'][1]
      ::Alto::CallbackManager.call(:ticket_status_changed, self, old_status_slug, new_status_slug, board, get_user_object(user_id))
    end

    def get_user_object(user_id)
      return nil unless user_id

      begin
        user_class = ::Alto.configuration.user_model.constantize
        user_class.find_by(id: user_id)
      rescue NameError
        nil
      end
    end

    def status_slug_valid_for_board
      return unless status_slug.present? && board.present?

      if board.has_status_tracking?
        valid_slugs = board.status_set.status_slugs
        unless valid_slugs.include?(status_slug)
          errors.add(:status_slug, "is not valid for this board")
        end
      else
        # Board has no status tracking, so status_slug should be nil
        unless status_slug.nil?
          errors.add(:status_slug, "should not be set for boards without status tracking")
        end
      end
    end

    def set_default_status
      return unless board.present?

      if board.has_status_tracking? && status_slug.blank?
        self.status_slug = board.default_status_slug
      elsif !board.has_status_tracking?
        self.status_slug = nil
      end
    end

    def set_user_type
      self.user_type = ::Alto.configuration.user_model if user_id.present?
    end
  end
end
