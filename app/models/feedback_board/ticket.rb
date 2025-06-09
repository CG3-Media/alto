module FeedbackBoard
  class Ticket < ApplicationRecord
    STATUSES = %w[open planned in_progress complete].freeze

    belongs_to :board
    has_many :comments, dependent: :destroy
    has_many :upvotes, as: :upvotable, dependent: :destroy

    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :user_id, presence: true
    validates :board_id, presence: true

    # Email notification callbacks
    after_create :send_new_ticket_notifications
    after_update :send_status_change_notifications, if: :saved_change_to_status?

    scope :by_status, ->(status) { where(status: status) }
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

    private

    def send_new_ticket_notifications
      return unless FeedbackBoard.configuration.notifications_enabled

      # Send to admin emails if configured
      if FeedbackBoard.configuration.notify_admins_of_new_tickets &&
         FeedbackBoard.configuration.admin_notification_emails.any?

        FeedbackBoard.configuration.admin_notification_emails.each do |email|
          NotificationMailer.new_ticket(self, email).deliver_later
        end
      end
    end

    def send_status_change_notifications
      return unless FeedbackBoard.configuration.notifications_enabled
      return unless FeedbackBoard.configuration.notify_ticket_author

      # Get the user's email for notification
      user_email = get_user_email(user_id)
      return unless user_email

      old_status = saved_changes['status'][0] if saved_changes['status']
      NotificationMailer.status_changed(self, user_email, old_status).deliver_later
    end

    def get_user_email(user_id)
      return nil unless user_id

      user_class = FeedbackBoard.configuration.user_model.constantize rescue nil
      return nil unless user_class

      user = user_class.find_by(id: user_id)
      user&.email if user&.respond_to?(:email)
    end
  end
end
