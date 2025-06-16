module Alto
  class SubscribersController < ::Alto::ApplicationController
    include SubscriptionScoped

    before_action :ensure_admin_access, except: [ :unsubscribe ]
    before_action :set_subscription, only: [ :destroy ]

    def index
      @subscriptions = @ticket.subscriptions.includes(:ticket).order(:email)
      @new_subscription = @ticket.subscriptions.build
    end

    def create
      result = ::Alto::SubscriptionService.call(:subscribe, @ticket, subscription_params[:email])

      if result.success?
        redirect_to_subscribers_with_message(:notice, result.notice)
      else
        @subscriptions = @ticket.subscriptions.includes(:ticket).order(:email)
        @new_subscription = result.subscription
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      result = ::Alto::SubscriptionService.call(:unsubscribe, @ticket, @subscription.email)

      if result.success?
        redirect_to_subscribers_with_message(:notice, result.notice)
      else
        redirect_to_subscribers_with_message(:alert, result.alert)
      end
    end

        def unsubscribe
      result = ::Alto::SubscriptionService.call(:unsubscribe_user, @ticket, nil, current_user)

      if result.notice
        redirect_to_ticket_with_message(:notice, result.notice)
      else
        redirect_to_ticket_with_message(:alert, result.alert)
      end
    end

    private

    def set_subscription
      @subscription = @ticket.subscriptions.find(params[:id])
    end

    def ensure_admin_access
      unless can_access_admin?
        redirect_to_ticket_with_message(:alert, "You do not have permission to manage subscribers.")
      end
    end

    def subscription_params
      params.require(:subscription).permit(:email)
    end
  end
end
