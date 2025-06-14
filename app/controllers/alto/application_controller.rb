module Alto
  # Inherit from host app's ApplicationController if it exists, otherwise ActionController::Base
  superclass = defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base
  class ApplicationController < superclass
    include AltoPermissions
    include BoardManagement
    include SubscriptionHelpers

    protect_from_forgery with: :exception

    # Force engine to use its own layout, not host app's layout
    layout "alto/application"

    before_action :authenticate_user!, unless: -> { Rails.env.test? }
    before_action :check_alto_access!, unless: -> { Rails.env.test? }

    # Make engine methods available to views
    helper_method :current_user



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

      # Default: redirect to Alto home
              redirect_to alto_home_path
    end

    def check_alto_access!
      unless can_access_alto?
        redirect_to alto_home_path, alert: "You do not have access to Alto"
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
  end
end
