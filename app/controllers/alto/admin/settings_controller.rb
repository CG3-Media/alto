module Alto
  module Admin
    class SettingsController < ::Alto::ApplicationController
      before_action :ensure_admin_access

      def show
        @config = ::Alto.configuration
      end

            def update
        # Save settings to database
        settings = {
          "app_name" => params[:app_name]
        }

        Setting.update_settings(settings)

        # Reload configuration from database
        Setting.load_into_configuration!

        redirect_to alto.admin_settings_path, notice: "Settings saved successfully and will persist across restarts"
      end

      private
    end
  end
end
