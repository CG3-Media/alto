module Alto
  class BoardsController < ::Alto::ApplicationController
    include BoardScoped

    before_action :set_board, only: [ :show, :edit, :update, :destroy ]
    before_action :ensure_can_manage_boards, only: [ :new, :create, :edit, :update, :destroy ]

    def redirect_to_default
      # Find accessible boards for this user
      accessible_boards = ::Alto::Board.accessible_to_user(current_user, current_user_is_admin: can_access_admin?)

      # Find the default board or any accessible board if default doesn't exist
      default_board = accessible_boards.find_by(slug: "feedback") ||
                      accessible_boards.first

      # If no accessible boards exist, redirect appropriately
      if default_board.nil?
        if can_manage_boards?
          redirect_to boards_path, notice: "No boards exist yet. Create your first board!"
        else
          redirect_to alto_home_path, alert: "No feedback boards are available to you."
        end
        return
      end

      # Set as current board (handled by BoardScoped concern)
      session[:current_board_slug] = default_board.slug

      redirect_to board_path(default_board), status: :moved_permanently
    end

        def index
      @boards = ::Alto::Board.accessible_to_user(current_user, current_user_is_admin: can_access_admin?)
                                     .ordered
                                     .includes(:tickets)

      # Set first board as context for the sidebar to work properly
      if @boards.any? && current_board.nil?
        session[:current_board_slug] = @boards.first.slug
      end
    end

    def show
      # Redirect to tickets index for this board
      redirect_to board_tickets_path(@board)
    end

    def new
      @board = Board.new
    end

    def create
      @board = Board.new(board_params)

      if @board.save
        redirect_to board_path(@board), notice: "Board was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @board.update(board_params)
        redirect_to board_path(@board), notice: "Board was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @board.can_be_deleted?
        redirect_to admin_boards_path, alert: "Cannot delete board with tickets. Move or delete tickets first."
        return
      end

      @board.destroy
      redirect_to admin_boards_path, notice: "Board was successfully deleted."
    end

    private

    # Override BoardScoped concern method because this controller uses :slug instead of :board_slug
    def set_board
      @board = ::Alto::Board.find(params[:slug])
      ensure_current_board_set
    end

    def board_params
      params.require(:board).permit(:name, :description)
    end

    def ensure_can_manage_boards
      unless can_manage_boards?
        redirect_to alto_home_path, alert: "You do not have permission to manage boards."
      end
    end
  end
end
