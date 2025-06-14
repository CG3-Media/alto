module Alto
  module BoardScoped
    extend ActiveSupport::Concern

    private

    def set_board(param_key = :board_slug)
      @board = ::Alto::Board.find(params[param_key])
      ensure_current_board_set
    end

    # Defensive method to handle potential NoMethodError with set_current_board
    def ensure_current_board_set
      if respond_to?(:set_current_board)
        set_current_board(@board)
      else
        # Fallback: set session directly if method is not available
        Rails.logger.warn "[Alto] set_current_board method not found, setting session directly"
        session[:current_board_slug] = @board.slug
        @current_board = @board
      end
    end

    def check_board_access_with_redirect
      unless can_access_board?(@board)
        redirect_to "/", alert: "You do not have permission to access this board."
      end
    end
  end
end
