module FeedbackBoard
  class BoardsController < ApplicationController
    before_action :set_board, only: [:show, :edit, :update, :destroy]
    before_action :ensure_can_manage_boards, only: [:new, :create, :edit, :update, :destroy]

    def redirect_to_default
      # Find or create the default board
      default_board = FeedbackBoard::Board.find_by(slug: 'feedback') ||
                      FeedbackBoard::Board.create!(
                        name: 'Feedback',
                        slug: 'feedback',
                        description: 'General feedback and feature requests'
                      )

      # Set as current board
      ensure_current_board_set(default_board)

      redirect_to board_path(default_board), status: :moved_permanently
    end

    def index
      @boards = FeedbackBoard::Board.ordered.includes(:tickets)
    end

    def show
      @board = FeedbackBoard::Board.find_by!(slug: params[:slug])

      # Set this as the current board in session
      ensure_current_board_set(@board)

      # Redirect to tickets index for this board
      redirect_to board_tickets_path(@board)
    end

    def new
      @board = Board.new
    end

    def create
      @board = Board.new(board_params)

      if @board.save
        redirect_to board_path(@board), notice: 'Board was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @board.update(board_params)
        redirect_to board_path(@board), notice: 'Board was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @board.can_be_deleted?
        redirect_to admin_boards_path, alert: 'Cannot delete board with tickets. Move or delete tickets first.'
        return
      end

      @board.destroy
      redirect_to admin_boards_path, notice: 'Board was successfully deleted.'
    end

    private

    def set_board
      @board = Board.find_by!(slug: params[:slug])
    end

    # Defensive method to handle potential NoMethodError with set_current_board
    def ensure_current_board_set(board)
      if respond_to?(:set_current_board)
        set_current_board(board)
      else
        # Fallback: set session directly if method is not available
        Rails.logger.warn "[FeedbackBoard] set_current_board method not found, setting session directly"
        session[:current_board_slug] = board.slug
        @current_board = board
      end
    end

    def board_params
      params.require(:board).permit(:name, :description)
    end

    def ensure_can_manage_boards
      unless can_manage_boards?
        redirect_to root_path, alert: 'You do not have permission to manage boards.'
      end
    end
  end
end
