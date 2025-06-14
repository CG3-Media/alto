module Alto
  # Service object to handle tracking ticket views for subscribed users
  class TicketViewTracker
    def initialize(ticket, user)
      @ticket = ticket
      @user = user
    end

    def track
      return false unless @user

      begin
        user_email = get_user_email
        return false unless user_email.present?

        update_subscription_view(user_email)
        true
      rescue => e
        Rails.logger.warn "[Alto] Failed to track ticket view: #{e.message}"
        false
      end
    end

    private

    attr_reader :ticket, :user

    def get_user_email
      ::Alto.configuration.user_email.call(@user.id)
    end

    def update_subscription_view(user_email)
      subscription = @ticket.subscriptions.find_by(email: user_email)
      subscription&.update_column(:last_viewed_at, Time.current)
    end
  end
end
