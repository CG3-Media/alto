module Alto
  class SubscribersController < ::Alto::ApplicationController
    before_action :set_board
    before_action :set_ticket
    before_action :ensure_admin_access, except: [ :unsubscribe_me ]
    before_action :set_subscription, only: [ :destroy ]

    def index
      @subscriptions = @ticket.subscriptions.includes(:ticket).order(:email)
      @new_subscription = @ticket.subscriptions.build
    end

    def create
      email = subscription_params[:email]

      # Find existing subscription or create new one
      @subscription = @ticket.subscriptions.find_or_initialize_by(email: email)

      if @subscription.persisted?
        # Already exists - just touch it to update timestamps
        @subscription.touch
        redirect_to alto.board_ticket_subscribers_path(@board, @ticket),
                    notice: "#{email} subscription updated. They can continue receiving notifications for this ticket."
      else
        # New subscription - try to save
        if @subscription.save
          redirect_to alto.board_ticket_subscribers_path(@board, @ticket),
                      notice: "Successfully subscribed #{email} to this ticket."
        else
          @subscriptions = @ticket.subscriptions.includes(:ticket).order(:email)
          @new_subscription = @subscription
          render :index, status: :unprocessable_entity
        end
      end
    end

    def destroy
      email = @subscription.email
      @subscription.destroy
      redirect_to alto.board_ticket_subscribers_path(@board, @ticket),
                  notice: "Successfully unsubscribed #{email} from this ticket."
    end

    def unsubscribe_me
      return redirect_to alto.board_ticket_path(@board, @ticket), alert: "You must be logged in to unsubscribe." unless current_user

      begin
        user_email = ::Alto.configuration.user_email.call(current_user.id)

        if user_email.blank?
          return redirect_to alto.board_ticket_path(@board, @ticket), alert: "Unable to determine your email address."
        end

        subscription = @ticket.subscriptions.find_by(email: user_email)

        if subscription
          subscription.destroy
                      redirect_to alto.board_ticket_path(@board, @ticket),
                        notice: "You have been unsubscribed from this ticket."
        else
            redirect_to alto.board_ticket_path(@board, @ticket),
                        notice: "You are not currently subscribed to this ticket."
        end
      rescue => e
        Rails.logger.error "[Alto] Failed to unsubscribe user: #{e.message}"
        redirect_to alto.board_ticket_path(@board, @ticket),
                    alert: "Failed to unsubscribe. Please try again."
      end
    end

    private

    def set_board
      @board = ::Alto::Board.find(params[:board_slug])
    end

    def set_ticket
      @ticket = @board.tickets.find(params[:ticket_id])
    end

    def set_subscription
      @subscription = @ticket.subscriptions.find(params[:id])
    end

    def ensure_admin_access
      unless can_access_admin?
        redirect_to alto.board_ticket_path(@board, @ticket), alert: "You do not have permission to manage subscribers."
      end
    end

    def subscription_params
      params.require(:subscription).permit(:email)
    end
  end
end
