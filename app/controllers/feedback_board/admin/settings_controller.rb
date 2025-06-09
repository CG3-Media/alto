module FeedbackBoard
  module Admin
    class SettingsController < ::FeedbackBoard::ApplicationController
      before_action :ensure_admin_access

      def show
        @config = ::FeedbackBoard.configuration
      end

            def update
        # Save settings to database
        settings = {
          'app_name' => params[:app_name]
        }

        Setting.update_settings(settings)

        # Reload configuration from database
        Setting.load_into_configuration!

        redirect_to feedback_board.admin_settings_path, notice: 'Settings saved successfully and will persist across restarts'
      end

      private

      def ensure_admin_access
        unless can_access_admin?
          redirect_to feedback_board.root_path, alert: 'You do not have permission to access the admin area'
        end
      end
    end
  end
end
