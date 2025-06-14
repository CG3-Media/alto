# Board session management concern
module BoardManagement
  extend ActiveSupport::Concern

  included do
    helper_method :current_board, :default_board
  end

  # Current board session management
  def current_board
    @current_board ||= begin
      if session[:current_board_slug].present?
        ::Alto::Board.find_by(slug: session[:current_board_slug]) || default_board || ::Alto::Board.first
      else
        default_board || ::Alto::Board.first
      end
    end
  end

  def set_current_board(board)
    session[:current_board_slug] = board.slug
    @current_board = board
  end

  def default_board
    @default_board ||= ::Alto::Board.find_by(slug: "feedback")
  end
end
