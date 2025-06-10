module FeedbackBoard
  class SubscribersController < ::FeedbackBoard::ApplicationController
    before_action :set_board
    before_action :set_ticket
    before_action :set_subscription, only: [:destroy]

    def index
      @subscriptions = @ticket.subscriptions.includes(:ticket).order(:email)
      @new_subscription = @ticket.subscriptions.build
    end

    def create
      @subscription = @ticket.subscriptions.build(subscription_params)

      if @subscription.save
        redirect_to feedback_board.board_ticket_subscribers_path(@board, @ticket),
                    notice: "Successfully subscribed #{@subscription.email} to this ticket."
      else
        @subscriptions = @ticket.subscriptions.includes(:ticket).order(:email)
        @new_subscription = @subscription
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      email = @subscription.email
      @subscription.destroy
      redirect_to feedback_board.board_ticket_subscribers_path(@board, @ticket),
                  notice: "Successfully unsubscribed #{email} from this ticket."
    end

    private

    def set_board
      @board = ::FeedbackBoard::Board.find(params[:board_slug])
    end

    def set_ticket
      @ticket = @board.tickets.find(params[:ticket_id])
    end

    def set_subscription
      @subscription = @ticket.subscriptions.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:email)
    end
  end
end
