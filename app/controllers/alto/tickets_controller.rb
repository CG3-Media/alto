module Alto
  class TicketsController < ::Alto::ApplicationController
    before_action :set_board
    before_action :set_ticket, only: [ :show, :edit, :update, :destroy ]
    before_action :check_submit_permission, only: [ :new, :create ]
    before_action :check_board_access
    before_action :ensure_not_archived, only: [ :edit, :update, :destroy ]

    # Make helper methods available to views
    helper_method :can_user_edit_ticket?, :current_user_subscribed?, :can_assign_tags?

    def index
      # Set this as the current board in session
      ensure_current_board_set(@board)

      @tickets = @board.tickets.active.includes(:upvotes, :comments)

      # Filter by viewable statuses for non-admin users
      @tickets = @tickets.with_viewable_statuses(is_admin: can_access_admin?)

      # Apply search filter
      @tickets = @tickets.search(params[:search]) if params[:search].present?

      # Apply status filter
      @tickets = @tickets.by_status(params[:status]) if params[:status].present?

      # Apply tag filter
      @tickets = @tickets.tagged_with(params[:tag]) if params[:tag].present?

      # Apply sorting
      @tickets = case params[:sort]
      when "popular"
                   @tickets.popular
      else
                   @tickets.recent
      end

      @tickets = @tickets.page(params[:page]) if respond_to?(:page)
      @statuses = @board.available_statuses_for_user(is_admin: can_access_admin?)
      @tags = @board.tags.used.ordered
      @search_query = params[:search]
      @selected_tag = params[:tag]

      # Determine view type based on board settings
      determine_view_type
    end

    def show
      # Set this as the current board in session
      ensure_current_board_set(@board)

      # Track view for subscribed users
      track_ticket_view if current_user

      @comment = ::Alto::Comment.new
      @threaded_comments = ::Alto::Comment.threaded_for_ticket(@ticket)
    end

    def new
      # Ensure current board is set
      ensure_current_board_set(@board)
      @ticket = @board.tickets.build
    end

    def create
      @ticket = @board.tickets.build(ticket_params)
      @ticket.user_id = current_user.id

      # Process multiselect fields (convert arrays to comma-separated strings)
      process_multiselect_fields(@ticket)

      if @ticket.save
        redirect_to [ @board, @ticket ], notice: "Ticket was successfully created."
      else
        render :new
      end
    end

    def edit
      # Users can edit their own tickets, admins can edit any ticket
      redirect_to [ @board, @ticket ] unless can_user_edit_ticket?(@ticket)
    end

    def update
      # Users can edit their own tickets, admins can edit any ticket
      redirect_to [ @board, @ticket ] unless can_user_edit_ticket?(@ticket)

      @ticket.assign_attributes(ticket_params)

      # Process multiselect fields (convert arrays to comma-separated strings)
      process_multiselect_fields(@ticket)

      if @ticket.save
        redirect_to [ @board, @ticket ], notice: "Ticket was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @ticket.destroy
      redirect_to board_tickets_url(@board), notice: "Ticket was successfully deleted."
    end

    private

    def set_board
      @board = ::Alto::Board.find(params[:board_slug])
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
        Rails.logger.warn "[Alto] set_current_board method not found, setting session directly"
        session[:current_board_slug] = board.slug
        @current_board = board
      end
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

      params.require(:ticket).permit(*permitted_params)
    end

    def check_submit_permission
      unless can_submit_tickets?
        redirect_to board_tickets_path(@board), alert: "You do not have permission to submit tickets"
      end
    end

    def check_board_access
      unless can_access_board?(@board)
        redirect_to home_path, alert: "You do not have permission to access this board."
      end
    end

    def can_user_edit_ticket?(ticket)
      return false unless current_user
      # Users can edit their own tickets, or admins can edit any ticket
      ticket.user_id == current_user.id || can_access_admin?
    end

    def current_user_subscribed?(ticket = @ticket)
      return false unless current_user

      begin
        user_email = ::Alto.configuration.user_email.call(current_user.id)
        return false unless user_email.present?

        ticket.subscriptions.exists?(email: user_email)
      rescue => e
        Rails.logger.warn "[Alto] Failed to check subscription status: #{e.message}"
        false
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

      # Debug logging to understand what's happening
      Rails.logger.info "[ALTO DEBUG] Board: #{@board.name}, single_view: #{@board.single_view.inspect}, params[:view]: #{params[:view].inspect}, stored_preference: #{session.dig(:view_preferences, @board.slug).inspect}, @view_type: #{@view_type.inspect}, @show_toggle: #{@show_toggle.inspect}"
    end

    def can_assign_tags?
      # Admins can always assign tags
      return true if can_access_admin?

      # Regular users can assign tags if board allows public tagging
      @board.allow_public_tagging?
    end

    def process_multiselect_fields(ticket)
      return unless ticket.field_values.is_a?(Hash)

      @board.fields.where(field_type: "multiselect").each do |field|
        field_key = field.label.parameterize.underscore

        if ticket.field_values[field_key].is_a?(Array)
          # Convert array to comma-separated string
          ticket.field_values[field_key] = ticket.field_values[field_key].reject(&:blank?).join(",")
        end
      end
    end
  end
end
