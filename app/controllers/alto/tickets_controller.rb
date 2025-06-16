module Alto
  class TicketsController < ::Alto::ApplicationController
    include BoardScoped
    include Ticketable
    include TicketPermissionChecker

    before_action :set_board
    before_action :set_ticket, only: [ :show, :edit, :update, :destroy ]
    before_action :check_submit_permission, only: [ :new, :create ]
    before_action :check_board_access_with_redirect
    before_action :ensure_not_archived, only: [ :edit, :update, :destroy ]

    def index
      base_tickets = @board.tickets.active.includes(:user, :board, :upvotes, :tags)
      @tickets = apply_ticket_filters(base_tickets).page(params[:page]).per(25)

      view_result = determine_view_type(@board)
      @view_type = view_result.view_type
      @show_toggle = view_result.show_toggle

      setup_filter_data
    end

    def show
      # Track view for subscribed users
      ::Alto::TicketViewTracker.new(@ticket, current_user).track if current_user

      @comment = ::Alto::Comment.new
      @threaded_comments = ::Alto::Comment.threaded_for_ticket(@ticket)
    end

    def new
      @ticket = @board.tickets.build
    end

    def create
      @ticket = @board.tickets.build(ticket_params)
      @ticket.user_id = current_user.id
      @ticket.process_multiselect_fields!

      if @ticket.save
        redirect_to [ @board, @ticket ], notice: "Ticket was successfully created."
      else
        render :new
      end
    end

    def edit
      return unless check_edit_permission(@ticket)
    end

    def update
      return unless check_edit_permission(@ticket)

      @ticket.assign_attributes(ticket_params)
      @ticket.process_multiselect_fields!

      if @ticket.save
        redirect_to [ @board, @ticket ], notice: "Ticket was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @ticket.destroy
      redirect_to [ @board, :tickets ], notice: "Ticket was successfully deleted."
    end

    private

    def set_ticket
      @ticket = @board.tickets.find(params[:id])
    end

    def ticket_params
      permissions = {
        can_access_admin: can_access_admin?,
        can_edit_tickets: can_edit_tickets?
      }

      ::Alto::TicketParameterBuilder.new(params, current_user, @board, permissions).build
    end

    def setup_filter_data
      @available_statuses = @board.available_statuses_for_user(is_admin: can_access_admin?)
      @available_tags = @board.tags.used.ordered.limit(20)
      @statuses = @board.available_statuses_for_user(is_admin: can_access_admin?)
    end
  end
end
