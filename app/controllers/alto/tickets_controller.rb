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
        respond_to do |format|
          format.html { redirect_to [ @board, @ticket ], notice: "Ticket was successfully created." }
          format.json { render json: {
            ticket: @ticket,
            success: true,
            redirect_url: url_for([ @board, @ticket ]),
            message: "Ticket was successfully created."
          }, status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new }
          format.json { render json: {
            errors: @ticket.errors.full_messages,
            success: false
          }, status: :unprocessable_entity }
        end
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
        respond_to do |format|
          format.html { redirect_to [ @board, @ticket ], notice: "Ticket was successfully updated." }
          format.json { render json: {
            ticket: @ticket,
            success: true,
            redirect_url: url_for([ @board, @ticket ]),
            message: "Ticket was successfully updated."
          }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: {
            errors: @ticket.errors.full_messages,
            success: false
          }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @ticket.destroy
      respond_to do |format|
        format.html { redirect_to [ @board, :tickets ], notice: "Ticket was successfully deleted." }
        format.json { render json: {
          success: true,
          message: "Ticket was successfully deleted."
        }, status: :ok }
      end
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
