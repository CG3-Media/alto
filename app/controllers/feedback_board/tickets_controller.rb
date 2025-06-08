module FeedbackBoard
  class TicketsController < ApplicationController
    before_action :set_ticket, only: [:show, :edit, :update, :destroy]
    before_action :check_submit_permission, only: [:new, :create]

    def index
      @tickets = Ticket.includes(:upvotes, :comments)

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
      @comment = Comment.new
      @comments = @ticket.comments.includes(:upvotes).recent
    end

    def new
      @ticket = Ticket.new
    end

    def create
      @ticket = Ticket.new(ticket_params)
      @ticket.user_id = current_user.id

      if @ticket.save
        redirect_to @ticket, notice: 'Ticket was successfully created.'
      else
        render :new
      end
    end

    def edit
      # Only admins should be able to edit tickets
      redirect_to @ticket unless can_edit_tickets?
    end

    def update
      if @ticket.update(ticket_params)
        redirect_to @ticket, notice: 'Ticket was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @ticket.destroy
      redirect_to tickets_url, notice: 'Ticket was successfully deleted.'
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    def ticket_params
      permitted_params = [:title, :description]
      permitted_params += [:status, :locked] if can_edit_tickets?
      params.require(:ticket).permit(*permitted_params)
    end

    def check_submit_permission
      unless can_submit_tickets?
        redirect_to tickets_path, alert: 'You do not have permission to submit tickets'
      end
    end


  end
end
