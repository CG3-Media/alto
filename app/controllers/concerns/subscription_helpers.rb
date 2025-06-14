# Subscription management concern
module SubscriptionHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_subscribed?
  end

  # Check if current user is subscribed to a ticket
  def current_user_subscribed?(ticket = nil)
    # Use @ticket if available, otherwise use provided ticket parameter
    target_ticket = ticket || instance_variable_get(:@ticket)
    return false unless current_user && target_ticket

    begin
      user_email = ::Alto.configuration.user_email.call(current_user.id)
      return false unless user_email.present?

      target_ticket.subscriptions.exists?(email: user_email)
    rescue => e
      Rails.logger.warn "[Alto] Failed to check subscription status: #{e.message}"
      false
    end
  end
end
