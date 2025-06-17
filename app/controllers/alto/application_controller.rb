module Alto
  # Inherit from host app's ApplicationController if it exists, otherwise ActionController::Base
  superclass = defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base
  class ApplicationController < superclass
    include AltoPermissions
    include BoardManagement
    include SubscriptionHelpers
    include EngineAuthentication
    include AltoAccessControl

    protect_from_forgery with: :exception

    # Force engine to use its own layout, not host app's layout
    layout "alto/application"

    before_action :authenticate_user!
    before_action :check_alto_access!
    before_action :handle_view_as_param

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    # Override can_access_admin? to support view_as functionality
    def can_access_admin?
      # If viewing as user, return false regardless of actual permissions
      return false if viewing_as_user?

      # Otherwise use normal permission check
      super
    end

    # Override can_edit_tickets? to support view_as functionality
    def can_edit_tickets?
      # If viewing as user, return false regardless of actual permissions
      return false if viewing_as_user?

      # Otherwise use normal permission check
      super
    end

    # Helper methods for view_as functionality
    def viewing_as_user?
      session[:view_as] == 'user'
    end

    def actual_admin?
      # Call the original permission check without our override
      check_configured_permission(:can_access_admin?) do
        return false unless current_user
        false # Default: secure by default - admin access should be explicitly granted
      end
    end

    helper_method :viewing_as_user?, :actual_admin?

    private

    def handle_view_as_param
      return unless params[:view_as]

      case params[:view_as]
      when 'user'
        # Only allow admins to view as user - check original permission without override
        if actual_admin?
          session[:view_as] = 'user'
        end
      when 'admin', 'reset', 'clear'
        # Clear view_as mode
        session.delete(:view_as)
      end
    end

    def not_found
      render plain: "Not Found", status: :not_found
    end
  end
end
