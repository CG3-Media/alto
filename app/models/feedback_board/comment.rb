module FeedbackBoard
  class Comment < ApplicationRecord
    belongs_to :ticket
    has_many :upvotes, as: :upvotable, dependent: :destroy

    validates :content, presence: true
    validates :user_id, presence: true

    # Email notification callbacks
    after_create :send_new_comment_notifications

    scope :recent, -> { order(created_at: :desc) }
    scope :popular, -> { left_joins(:upvotes).group(:id).order('count(feedback_board_upvotes.id) desc') }

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

    private

    def send_new_comment_notifications
      return unless FeedbackBoard.configuration.notifications_enabled

      # Send to admin emails if configured
      if FeedbackBoard.configuration.notify_admins_of_new_comments &&
         FeedbackBoard.configuration.admin_notification_emails.any?

        FeedbackBoard.configuration.admin_notification_emails.each do |email|
          NotificationMailer.new_comment(self, email).deliver_later
        end
      end

      # Send to ticket author if configured and it's not their own comment
      if FeedbackBoard.configuration.notify_ticket_author &&
         ticket.user_id != user_id

        user_email = get_user_email(ticket.user_id)
        if user_email
          NotificationMailer.new_comment(self, user_email).deliver_later
        end
      end
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
