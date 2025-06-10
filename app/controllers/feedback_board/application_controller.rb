module FeedbackBoard
  # Inherit from host app's ApplicationController if it exists, otherwise ActionController::Base
  superclass = defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base
  class ApplicationController < superclass
    protect_from_forgery with: :exception

    before_action :authenticate_user!
    before_action :check_feedback_board_access!

    # Auto-detect and register permission methods from host app as helpers
    PERMISSION_METHODS = [
      :can_access_feedback_board?, :can_submit_tickets?, :can_comment?,
      :can_vote?, :can_edit_tickets?, :can_access_admin?, :can_manage_boards?,
      :can_access_board?
    ].freeze

    # Make engine methods available to views
    helper_method :current_board, :default_board

    # Auto-register host app permission methods as helpers
    PERMISSION_METHODS.each do |method_name|
      if defined?(::ApplicationController) &&
         (::ApplicationController.instance_methods(true).include?(method_name) ||
          ::ApplicationController.private_instance_methods(true).include?(method_name))
        helper_method method_name
      end
    end

    # Always make engine versions available as helpers too
    helper_method *PERMISSION_METHODS

    # Permission methods with sensible defaults
    # These methods delegate to the host app's ApplicationController if available
    # Otherwise they use sensible defaults

    def can_access_feedback_board?
      check_configured_permission(:can_access_feedback_board?) do
        return false unless current_user
        true # Default: allow access if user is logged in
      end
    end

    def can_submit_tickets?
      check_configured_permission(:can_submit_tickets?) do
        return false unless current_user
        true # Default: allow ticket submission if user is logged in
      end
    end

    def can_comment?
      check_configured_permission(:can_comment?) do
        return false unless current_user
        true # Default: allow commenting if user is logged in
      end
    end

    def can_vote?
      check_configured_permission(:can_vote?) do
        return false unless current_user
        true # Default: allow voting if user is logged in
      end
    end

    def can_edit_tickets?
      check_configured_permission(:can_edit_tickets?) do
        return false unless current_user
        false # Default: secure by default - only admins should edit
      end
    end

    def can_access_admin?
      check_configured_permission(:can_access_admin?) do
        return false unless current_user
        can_edit_tickets? # Default: fallback to edit permission
      end
    end

    def can_manage_boards?
      check_configured_permission(:can_manage_boards?) do
        return false unless current_user
        can_edit_tickets? # Default: fallback to edit permission
      end
    end

    def can_access_board?(board = nil)
      check_configured_permission(:can_access_board?, board) do
        return false unless current_user

        # Check if board is admin-only and user has admin access
        if board&.admin_only?
          return can_access_admin?
        end

        true # Default: allow access to public boards if user is logged in
      end
    end

    # Current board session management
    def current_board
      @current_board ||= begin
        if session[:current_board_slug].present?
          ::FeedbackBoard::Board.find_by(slug: session[:current_board_slug]) || default_board || ::FeedbackBoard::Board.first
        else
          default_board || ::FeedbackBoard::Board.first
        end
      end
    end

    def set_current_board(board)
      session[:current_board_slug] = board.slug
      @current_board = board
    end

    def default_board
      @default_board ||= ::FeedbackBoard::Board.find_by(slug: 'feedback')
    end

    private

    def authenticate_user!
      # Only redirect if current_user is nil AND the host app doesn't have its own authentication
      return if current_user

      # Check if host app has its own authenticate_user! method
      if defined?(::ApplicationController) &&
         (::ApplicationController.instance_methods(true).include?(:authenticate_user!) ||
          ::ApplicationController.private_instance_methods(true).include?(:authenticate_user!))
        begin
          # Call the host app's authentication method
          super
          return
        rescue NoMethodError
          # Host app method doesn't exist, fall through to default
        end
      end

      # Default: redirect to root with fallback for test environment
      if defined?(main_app) && main_app.respond_to?(:root_path)
        redirect_to main_app.root_path
      else
        redirect_to feedback_board.root_path
      end
    end

    def check_feedback_board_access!
      unless can_access_feedback_board?
        if defined?(main_app) && main_app.respond_to?(:root_path)
          redirect_to main_app.root_path, alert: 'You do not have access to the feedback board'
        else
          redirect_to feedback_board.root_path, alert: 'You do not have access to the feedback board'
        end
      end
    end

        def current_user
      # Since we inherit from the host app's ApplicationController,
      # current_user should be available automatically.
      # If not, try main_app as fallback
      super
    rescue NoMethodError
      # Fallback: try main_app helper (for engines)
      begin
        main_app.current_user if main_app.respond_to?(:current_user)
      rescue => e
        Rails.logger.debug "[FeedbackBoard] Could not get current_user: #{e.message}"
        nil
      end
    end



    # Check for permission methods defined in the initializer configuration
    # Falls back to provided block if method doesn't exist in config
    def check_configured_permission(method_name, *args, &fallback_block)
      # Check if the host app defined this permission in the initializer
      if ::FeedbackBoard.config.has_permission?(method_name)
        Rails.logger.debug "[FeedbackBoard] Using configured permission for #{method_name}"
        return ::FeedbackBoard.config.call_permission(method_name, self, *args)
      else
        Rails.logger.debug "[FeedbackBoard] No configured permission for #{method_name}, using default"
        return fallback_block.call
      end
    end
  end
end
