module FeedbackBoard
  class Configuration
    attr_accessor :user_display_name_method, :user_model,
                  :app_name,
                  :notifications_enabled, :notification_from_email,
                  :admin_notification_emails, :notify_ticket_author,
                  :notify_admins_of_new_tickets, :notify_admins_of_new_comments,
                  :default_board_name, :default_board_slug,
                  :allow_board_deletion_with_tickets

    def initialize
      # Default configuration: try common name fields, fallback to email
      @user_display_name_method = default_user_display_name_method
      @user_model = "User"

      # App branding
      @app_name = "Feedback Board"

      # Email notification defaults
      @notifications_enabled = true
      @notification_from_email = "noreply@example.com"
      @admin_notification_emails = []
      @notify_ticket_author = true
      @notify_admins_of_new_tickets = true
      @notify_admins_of_new_comments = true

      # Board configuration defaults
      @default_board_name = "Feedback"
      @default_board_slug = "feedback"
      @allow_board_deletion_with_tickets = false
    end

    private

    def default_user_display_name_method
      proc do |user_id|
        return "Anonymous" unless user_id

        # Get the user model class (configurable, defaults to User)
        user_class = user_model.constantize rescue nil
        return "Anonymous" unless user_class

        user = user_class.find_by(id: user_id)
        return "Anonymous" unless user

        # Try different name fields in order of preference
        if user.respond_to?(:full_name) && user.full_name.present?
          user.full_name
        elsif user.respond_to?(:first_name) && user.respond_to?(:last_name) &&
              (user.first_name.present? || user.last_name.present?)
          "#{user.first_name} #{user.last_name}".strip
        elsif user.respond_to?(:first_name) && user.first_name.present?
          user.first_name
        elsif user.respond_to?(:last_name) && user.last_name.present?
          user.last_name
        elsif user.respond_to?(:email) && user.email.present?
          user.email
        else
          "User ##{user_id}"
        end
      end
    end
  end
end
