module Alto
  class TicketsController < ::Alto::ApplicationController
    include BoardScoped

    before_action :set_board
    before_action :set_ticket, only: [ :show, :edit, :update, :destroy ]
    before_action :check_submit_permission, only: [ :new, :create ]
    before_action :check_board_access_with_redirect
    before_action :ensure_not_archived, only: [ :edit, :update, :destroy ]

    # Make helper methods available to views
    helper_method :can_assign_tags?

    def index
      # Apply status filtering
      @tickets = @board.tickets.active.includes(:user, :board, :upvotes, :tags)

      # Filter by status if provided
      if params[:status].present?
        @tickets = @tickets.by_status(params[:status])
      end

      # Filter tickets by viewable statuses for non-admin users
      @tickets = @tickets.with_viewable_statuses(is_admin: can_access_admin?)

      # Filter by tag if provided
      if params[:tag].present?
        @tickets = @tickets.tagged_with(params[:tag])
      end

      # Apply search if provided
      if params[:search].present?
        @tickets = @tickets.search(params[:search])
      end

      # Apply sorting
      case params[:sort]
      when "popular"
        @tickets = @tickets.popular
      else
        @tickets = @tickets.recent
      end

      # Paginate
      @tickets = @tickets.page(params[:page]).per(25)

      # Determine view type (card or list) based on URL param, user preference, or board setting
      determine_view_type

      # Get available statuses for filtering dropdown
      @available_statuses = @board.available_statuses_for_user(is_admin: can_access_admin?)

      # Get available tags for filtering
      @available_tags = @board.tags.used.ordered.limit(20)

      # Get available statuses for card view
      @statuses = @board.available_statuses_for_user(is_admin: can_access_admin?)
    end

    def show
      # Track view for subscribed users
      track_ticket_view if current_user

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
      # Users can edit their own tickets, admins can edit any ticket
      unless @ticket.editable_by?(current_user, can_edit_any_ticket: can_edit_tickets?)
        redirect_to [ @board, @ticket ]
        return
      end
    end

    def update
      # Users can edit their own tickets, admins can edit any ticket
      unless @ticket.editable_by?(current_user, can_edit_any_ticket: can_edit_tickets?)
        redirect_to [ @board, @ticket ]
        return
      end

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
      permitted_params = [ :title, :description ]
      # Only admins can edit status and locked fields
      permitted_params += [ :status_slug, :locked ] if can_access_admin?

      # Allow tag assignment based on permissions
      if can_assign_tags?
        permitted_params << { tag_ids: [] }
      end

      # Allow all field_values as a hash - more flexible approach
      permitted_params << { field_values: {} }

      # Allow image uploads if enabled
      if ::Alto.configuration.image_uploads_enabled
        permitted_params << :images  # Single file (multiple: false)
        permitted_params << { images: [] }  # Array format (if multiple: true)
        permitted_params << :remove_images  # Allow image removal
      end

      params.require(:ticket).permit(*permitted_params)
    end

    def check_submit_permission
      unless can_submit_tickets?
        redirect_to [ @board, :tickets ], alert: "You do not have permission to submit tickets"
      end
    end



    def track_ticket_view
      return unless current_user

      begin
        # Get user email using the configuration system
        user_email = ::Alto.configuration.user_email.call(current_user.id)
        return unless user_email.present?

        # Find and update subscription if it exists
        subscription = @ticket.subscriptions.find_by(email: user_email)
        subscription&.update_column(:last_viewed_at, Time.current)
      rescue => e
        # Log error but don't break the page load
        Rails.logger.warn "[Alto] Failed to track ticket view: #{e.message}"
      end
    end

    def ensure_not_archived
      if @ticket.archived?
        redirect_to [ @board, @ticket ], alert: "Archived tickets cannot be modified."
      end
    end

    def determine_view_type
      # If board enforces a single view, use that
      if @board.single_view.present?
        @view_type = @board.single_view
        @show_toggle = false
        return
      end

      # If user explicitly chose a view via URL parameter, use it and store preference
      if params[:view].present?
        @view_type = params[:view] == "list" ? "list" : "card"
        # Store user's view preference in session for this board
        session[:view_preferences] ||= {}
        session[:view_preferences][@board.slug] = @view_type
      else
        # No URL parameter - check for stored preference, fallback to default
        stored_preferences = session[:view_preferences] || {}
        @view_type = stored_preferences[@board.slug] || "list"
      end

      @show_toggle = true
    end

    def can_assign_tags?
      @board.tags_assignable_by?(current_user, can_edit_any_ticket: can_edit_tickets?)
    end
  end
end
