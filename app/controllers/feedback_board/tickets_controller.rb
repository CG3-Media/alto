module FeedbackBoard
  class TicketsController < ApplicationController
    before_action :set_board
    before_action :set_ticket, only: [:show, :edit, :update, :destroy]
    before_action :check_submit_permission, only: [:new, :create]
    before_action :check_board_access

    # Make helper methods available to views
    helper_method :can_user_edit_ticket?

    def index
      # Set this as the current board in session
      ensure_current_board_set(@board)

      @tickets = @board.tickets.includes(:upvotes, :comments)

      # Apply search filter
      @tickets = @tickets.search(params[:search]) if params[:search].present?

      # Apply status filter
      @tickets = @tickets.by_status(params[:status]) if params[:status].present?

      # Apply sorting
      @tickets = case params[:sort]
                 when 'popular'
                   @tickets.popular
                 else
                   @tickets.recent
                 end

      @tickets = @tickets.page(params[:page]) if respond_to?(:page)
      @statuses = Ticket::STATUSES
      @search_query = params[:search]
    end

    def show
      # Set this as the current board in session
      ensure_current_board_set(@board)

      @comment = FeedbackBoard::Comment.new
      @threaded_comments = FeedbackBoard::Comment.threaded_for_ticket(@ticket)
    end

    def new
      # Ensure current board is set
      ensure_current_board_set(@board)
      @ticket = @board.tickets.build
    end

    def create
      @ticket = @board.tickets.build(ticket_params)
      @ticket.user_id = current_user.id

      if @ticket.save
        redirect_to [@board, @ticket], notice: 'Ticket was successfully created.'
      else
        render :new
      end
    end

    def edit
      # Users can edit their own tickets, admins can edit any ticket
      redirect_to [@board, @ticket] unless can_user_edit_ticket?(@ticket)
    end

    def update
      # Users can edit their own tickets, admins can edit any ticket
      redirect_to [@board, @ticket] unless can_user_edit_ticket?(@ticket)

      if @ticket.update(ticket_params)
        redirect_to [@board, @ticket], notice: 'Ticket was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @ticket.destroy
      redirect_to board_tickets_url(@board), notice: 'Ticket was successfully deleted.'
    end

    private

    def set_board
      @board = FeedbackBoard::Board.find_by!(slug: params[:board_slug])
    end

    def set_ticket
      @ticket = @board.tickets.find(params[:id])
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

    def ticket_params
      permitted_params = [:title, :description]
      # Only admins can edit status and locked fields
      permitted_params += [:status, :locked] if can_edit_tickets?
      params.require(:ticket).permit(*permitted_params)
    end

    def check_submit_permission
      unless can_submit_tickets?
        redirect_to board_tickets_path(@board), alert: 'You do not have permission to submit tickets'
      end
    end

    def check_board_access
      unless can_access_board?(@board)
        redirect_to root_path, alert: 'You do not have permission to access this board.'
      end
    end

    def can_user_edit_ticket?(ticket)
      return false unless current_user
      # Users can edit their own tickets, or admins can edit any ticket
      ticket.user_id == current_user.id || can_edit_tickets?
    end

  end
end
