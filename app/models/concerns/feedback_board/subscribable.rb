module FeedbackBoard
  module Subscribable
    extend ActiveSupport::Concern

    included do
      after_create :create_user_subscription, if: :should_create_subscription?
    end

    private

    def create_user_subscription
      return unless user_id.present?
      return unless respond_to?(:user_email) && user_email.present?

      target_ticket = subscribable_ticket
      return unless target_ticket

      begin
        target_ticket.subscriptions.find_or_create_by(email: user_email)
      rescue => e
        Rails.logger.warn "[FeedbackBoard] Failed to create subscription: #{e.message}"
        # Don't raise - subscription failure shouldn't break the main flow
      end
    end

    def should_create_subscription?
      # Override in including models if needed
      true
    end

    def subscribable_ticket
      # Override in including models to specify which ticket to subscribe to
      raise NotImplementedError, "#{self.class} must implement #subscribable_ticket"
    end

    def user_email
      # Override in including models to specify how to get user email
      raise NotImplementedError, "#{self.class} must implement #user_email"
    end
  end
end
