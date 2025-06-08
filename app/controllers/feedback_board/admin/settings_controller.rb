module FeedbackBoard
  module Admin
    class SettingsController < FeedbackBoard::ApplicationController
      before_action :ensure_admin_access

      def show
        @config = FeedbackBoard.configuration
      end

            def update
        # Process admin emails (convert comma-separated string to array)
        admin_emails = if params[:admin_notification_emails].present?
          params[:admin_notification_emails].split(',').map(&:strip).reject(&:blank?)
        else
          []
        end

        # Save settings to database
        settings = {
          'notifications_enabled' => params[:notifications_enabled] == '1',
          'notification_from_email' => params[:notification_from_email],
          'notify_ticket_author' => params[:notify_ticket_author] == '1',
          'notify_admins_of_new_tickets' => params[:notify_admins_of_new_tickets] == '1',
          'notify_admins_of_new_comments' => params[:notify_admins_of_new_comments] == '1',
          'admin_notification_emails' => admin_emails
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
