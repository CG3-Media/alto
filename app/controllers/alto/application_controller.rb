module Alto
  # Inherit from host app's ApplicationController if it exists, otherwise ActionController::Base
  superclass = defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base
  class ApplicationController < superclass
    protect_from_forgery with: :exception

    # Force engine to use its own layout, not host app's layout
    layout 'alto/application'

    before_action :authenticate_user!, unless: -> { Rails.env.test? }
    before_action :check_alto_access!, unless: -> { Rails.env.test? }

    # Auto-detect and register permission methods from host app as helpers
    PERMISSION_METHODS = [
      :can_access_alto?, :can_submit_tickets?, :can_comment?,
      :can_vote?, :can_edit_tickets?, :can_access_admin?, :can_manage_boards?,
      :can_access_board?
    ].freeze

    # Make engine methods available to views
    helper_method :current_board, :default_board, :current_user

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

    def can_access_alto?
      check_configured_permission(:can_access_alto?) do
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
        false # Default: secure by default - admin access should be explicitly granted
      end
    end

    def can_manage_boards?
      check_configured_permission(:can_manage_boards?) do
        return false unless current_user
        false # Default: secure by default - board management should be explicitly granted
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
          ::Alto::Board.find_by(slug: session[:current_board_slug]) || default_board || ::Alto::Board.first
        else
          default_board || ::Alto::Board.first
        end
      end
    end

    def set_current_board(board)
      session[:current_board_slug] = board.slug
      @current_board = board
    end

    def default_board
      @default_board ||= ::Alto::Board.find_by(slug: 'feedback')
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
        redirect_to alto.root_path
      end
    end

    def check_alto_access!
      unless can_access_alto?
        if defined?(main_app) && main_app.respond_to?(:root_path)
          redirect_to main_app.root_path, alert: 'You do not have access to Alto'
        else
          redirect_to alto.root_path, alert: 'You do not have access to Alto'
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
        Rails.logger.debug "[Alto] Could not get current_user: #{e.message}"
        nil
      end
    end

                # Check for permission methods defined in the initializer configuration
    # Falls back to provided block if method doesn't exist in config
        def check_configured_permission(method_name, *args, &fallback_block)
      # Skip delegation for test controllers (they should use secure defaults)
      unless self.class.name.include?('Test')
        # First check if the host app (super class) has this method defined
        if defined?(::ApplicationController) &&
           (::ApplicationController.instance_methods(true).include?(method_name) ||
            ::ApplicationController.private_instance_methods(true).include?(method_name))

          begin
            # Call the method directly on the superclass, not super which looks for check_configured_permission
            return ::ApplicationController.instance_method(method_name).bind(self).call(*args)
          rescue NoMethodError => e
            # Fall through to other checks
          end
        end
      end

      # For test controllers, skip configured permissions and use defaults (for testing engine behavior)
      unless self.class.name.include?('Test')
        # Check if the host app defined this permission in the initializer
        if defined?(::Alto.config) && ::Alto.config.respond_to?(:has_permission?) && ::Alto.config.has_permission?(method_name)
          return ::Alto.config.call_permission(method_name, self, *args)
        end
      end

      return fallback_block.call
    end
  end
end
