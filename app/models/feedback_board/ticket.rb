module FeedbackBoard
  class Ticket < ApplicationRecord
    belongs_to :board
    has_many :comments, dependent: :destroy
    has_many :upvotes, as: :upvotable, dependent: :destroy

    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true
    validates :user_id, presence: true
    validates :board_id, presence: true
    validate :status_slug_valid_for_board

    # Email notification callbacks
    after_create :send_new_ticket_notifications
    after_update :send_status_change_notifications, if: :saved_change_to_status_slug?

    # Host app callback hooks
    after_create :trigger_ticket_created_callback
    after_update :trigger_ticket_status_changed_callback, if: :saved_change_to_status_slug?

    # Set default status when ticket is created
    before_create :set_default_status

    scope :by_status, ->(status_slug) { where(status_slug: status_slug) }
    scope :unlocked, -> { where(locked: false) }
    scope :locked, -> { where(locked: true) }
    scope :recent, -> { order(created_at: :desc) }
    scope :popular, -> { left_joins(:upvotes).group(:id).order('count(feedback_board_upvotes.id) desc') }
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
        joins(:comments).where("feedback_board_comments.content ILIKE ?", sanitized_query)
      else
        joins(:comments).where("LOWER(feedback_board_comments.content) LIKE LOWER(?)", sanitized_query)
      end
    }

        scope :search, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"

      # Combined search in tickets OR comments with a single query
      if connection.adapter_name.downcase.include?('postgresql')
        left_joins(:comments).where(
          "(feedback_board_tickets.title ILIKE ? OR feedback_board_tickets.description ILIKE ?) OR feedback_board_comments.content ILIKE ?",
          sanitized_query, sanitized_query, sanitized_query
        ).distinct
      else
        left_joins(:comments).where(
          "(LOWER(feedback_board_tickets.title) LIKE LOWER(?) OR LOWER(feedback_board_tickets.description) LIKE LOWER(?)) OR LOWER(feedback_board_comments.content) LIKE LOWER(?)",
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

    private

    def send_new_ticket_notifications
      return unless ::FeedbackBoard.configuration.notifications_enabled

      # Send to admin emails if configured
      if ::FeedbackBoard.configuration.notify_admins_of_new_tickets &&
         ::FeedbackBoard.configuration.admin_notification_emails.any?

        ::FeedbackBoard.configuration.admin_notification_emails.each do |email|
          NotificationMailer.new_ticket(self, email).deliver_later
        end
      end
    end

    def send_status_change_notifications
          return unless ::FeedbackBoard.configuration.notifications_enabled
    return unless ::FeedbackBoard.configuration.notify_ticket_author

      # Get the user's email for notification
      user_email = get_user_email(user_id)
      return unless user_email

      old_status_slug = saved_changes['status_slug'][0] if saved_changes['status_slug']
      NotificationMailer.status_changed(self, user_email, old_status_slug).deliver_later
    end

    def get_user_email(user_id)
      return nil unless user_id

      user_class = ::FeedbackBoard.configuration.user_model.constantize rescue nil
      return nil unless user_class

      user = user_class.find_by(id: user_id)
      user&.email if user&.respond_to?(:email)
    end

    def trigger_ticket_created_callback
      ::FeedbackBoard::CallbackManager.call(:ticket_created, self, board, get_user_object(user_id))
    end

    def trigger_ticket_status_changed_callback
      old_status_slug = saved_changes['status_slug'][0]
      new_status_slug = saved_changes['status_slug'][1]
      ::FeedbackBoard::CallbackManager.call(:ticket_status_changed, self, old_status_slug, new_status_slug, board, get_user_object(user_id))
    end

    def get_user_object(user_id)
      return nil unless user_id

      user_class = ::FeedbackBoard.configuration.user_model.constantize rescue nil
      return nil unless user_class

      user_class.find_by(id: user_id)
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
  end
end
