module AltoAccessControl
  extend ActiveSupport::Concern

  private

  def check_alto_access!
    unless can_access_alto?
      redirect_to main_app.root_path, alert: "You do not have access to Alto" rescue redirect_to "/", alert: "You do not have access to Alto"
    end
  end
end
