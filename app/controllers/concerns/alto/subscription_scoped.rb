module Alto
  module SubscriptionScoped
    extend ActiveSupport::Concern

    included do
      before_action :set_board
      before_action :set_ticket
    end

    private

    def set_board
      @board = ::Alto::Board.find(params[:board_slug])
    end

    def set_ticket
      @ticket = @board.tickets.find(params[:ticket_id])
    end

    def redirect_to_ticket_with_message(type, message)
      redirect_to alto.board_ticket_path(@board, @ticket), type => message
    end

    def redirect_to_subscribers_with_message(type, message)
      redirect_to alto.board_ticket_subscribers_path(@board, @ticket), type => message
    end
  end
end
