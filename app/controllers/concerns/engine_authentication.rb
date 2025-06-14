module EngineAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  private

  def authenticate_user!
    return if current_user

    if host_app_has_authentication?
      delegate_to_host_authentication
    else
      redirect_to alto_home_path
    end
  end

  def current_user
    # Try to inherit from host app's ApplicationController
    super
  rescue NoMethodError
    # Fallback: try main_app helper (for engines)
    fallback_current_user
  end

  def host_app_has_authentication?
    defined?(::ApplicationController) &&
      (::ApplicationController.instance_methods(true).include?(:authenticate_user!) ||
       ::ApplicationController.private_instance_methods(true).include?(:authenticate_user!))
  end

  def delegate_to_host_authentication
    super
  rescue NoMethodError
    # Host app method doesn't exist, use default
    redirect_to alto_home_path
  end

  def fallback_current_user
    return nil unless main_app.respond_to?(:current_user)

    main_app.current_user
  rescue => e
    Rails.logger.debug "[Alto] Could not get current_user: #{e.message}"
    nil
  end
end
