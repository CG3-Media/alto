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

    before_action :authenticate_user!, unless: -> { Rails.env.test? }
    before_action :check_alto_access!, unless: -> { Rails.env.test? }
  end
end
