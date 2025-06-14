module AltoAccessControl
  extend ActiveSupport::Concern

  private

  def check_alto_access!
    unless can_access_alto?
      redirect_to alto_home_path, alert: "You do not have access to Alto"
    end
  end
end
