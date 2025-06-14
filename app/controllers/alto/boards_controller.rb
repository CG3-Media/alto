module Alto
  class BoardsController < ::Alto::ApplicationController
    include BoardScoped

    before_action :set_board, only: [ :show, :edit, :update, :destroy ]
    before_action :ensure_can_manage_boards, only: [ :new, :create, :edit, :update, :destroy ]

        def redirect_to_default
      default_board = Board.find_default_for_user(current_user, current_user_is_admin: can_access_admin?)

      if default_board.nil?
        if can_manage_boards?
          redirect_to boards_path, notice: "No boards exist yet. Create your first board!"
        else
          redirect_to boards_path, alert: "No feedback boards are available to you."
        end
        return
      end

      # Set as current board
      session[:current_board_slug] = default_board.slug
      redirect_to board_path(default_board), status: :moved_permanently
    end

    def index
      @boards = BoardAccessService.accessible_boards_for(current_user, current_user_is_admin: can_access_admin?)

      # Set first board as context for the sidebar to work properly
      BoardAccessService.set_current_board_if_needed(@boards, session)
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
        redirect_to boards_path, alert: "You do not have permission to manage boards."
      end
    end
  end
end
