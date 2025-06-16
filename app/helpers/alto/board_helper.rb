module Alto
  module BoardHelper
    def board_item_name(board)
      board&.item_name || "ticket"
    end

    def current_board_item_name
      current_board&.item_name || "ticket"
    end

    def board_allows_voting?(upvotable)
      case upvotable
      when ::Alto::Ticket
        # For tickets, check the board's voting setting
        upvotable.board&.allow_voting? != false
      when ::Alto::Comment
        # Comments are always upvotable regardless of board setting
        true
      else
        # Default to true for other types
        true
      end
    end

    # Current board helper method (depends on session - harder to test)
    def current_board
      @current_board ||= begin
        if session[:current_board_slug].present?
          ::Alto::Board.find_by(slug: session[:current_board_slug]) || default_board || ::Alto::Board.first
        else
          default_board || ::Alto::Board.first
        end
      end
    end

    # Default board helper method (depends on database - harder to test)
    def default_board
      @default_board ||= ::Alto::Board.find_by(slug: "feedback")
    end
  end
end
