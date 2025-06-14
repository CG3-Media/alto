require 'ostruct'

module Alto
  class SubscriptionService
    def self.call(action, ticket, user_or_email, current_user = nil)
      new(action, ticket, user_or_email, current_user).call
    end

    def initialize(action, ticket, user_or_email, current_user = nil)
      @action = action.to_sym
      @ticket = ticket
      @user_or_email = user_or_email
      @current_user = current_user
    end

    def call
      case @action
      when :subscribe
        handle_subscribe
      when :unsubscribe
        handle_unsubscribe
      when :unsubscribe_user
        handle_user_unsubscribe
      else
        failure("Invalid action: #{@action}")
      end
    end

    private

    def handle_subscribe
      email = @user_or_email
      subscription = @ticket.subscriptions.find_or_initialize_by(email: email)

      if subscription.persisted?
        # Already exists - just touch it to update timestamps
        subscription.touch
        success("#{email} subscription updated. They can continue receiving notifications for this ticket.", subscription, :updated)
      else
        # New subscription - try to save
        if subscription.save
          success("Successfully subscribed #{email} to this ticket.", subscription, :created)
        else
          failure("Failed to create subscription.", subscription)
        end
      end
    end

    def handle_unsubscribe
      email = @user_or_email
      subscription = @ticket.subscriptions.find_by(email: email)

      if subscription
        subscription.destroy
        success("Successfully unsubscribed #{email} from this ticket.", subscription, :destroyed)
      else
        failure("#{email} is not subscribed to this ticket.", nil)
      end
    end

    def handle_user_unsubscribe
      return failure("You must be logged in to unsubscribe.") unless @current_user

      user_email = get_user_email
      return failure("Unable to determine your email address.") if user_email.blank?

      subscription = @ticket.subscriptions.find_by(email: user_email)

      if subscription
        subscription.destroy
        success("You have been unsubscribed from this ticket.", subscription, :destroyed)
      else
        success("You are not currently subscribed to this ticket.", nil, :not_found)
      end
    rescue => e
      Rails.logger.error "[Alto] Failed to unsubscribe user: #{e.message}"
      failure("Failed to unsubscribe. Please try again.")
    end

    def get_user_email
      ::Alto.configuration.user_email.call(@current_user.id)
    end

    def success(message, subscription = nil, operation = nil)
      OpenStruct.new(
        success?: true,
        notice: message,
        alert: nil,
        subscription: subscription,
        operation: operation
      )
    end

    def failure(message, subscription = nil)
      OpenStruct.new(
        success?: false,
        notice: nil,
        alert: message,
        subscription: subscription,
        operation: :failed
      )
    end
  end
end
