module FeedbackBoard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install FeedbackBoard"

      def install_feedback_board
        say "Installing FeedbackBoard...", :green

        # Set up database
        say "Setting up database schema...", :blue
        FeedbackBoard::DatabaseSetup.setup_if_needed

        # Create initializer
        create_initializer

        say "FeedbackBoard installation complete! 🎉", :green
        say ""
        say "Next steps:", :yellow
        say "1. Configure the initializer at config/initializers/feedback_board.rb"
        say "2. Mount the engine in your routes: mount FeedbackBoard::Engine => '/feedback'"
        say "3. Visit /feedback in your app to start using it!"
      end

      private

      def create_initializer
        initializer_content = <<~RUBY
          # FeedbackBoard Configuration
          FeedbackBoard.configure do |config|
            # User model configuration
            config.user_model = "User"
            config.user_display_name_method = :name  # or :email, :username, etc.

            # Permission methods (customize these for your authentication system)
            config.permission :can_submit_tickets? do |user|
              user.present?  # All logged-in users can submit tickets
            end

            config.permission :can_comment? do |user|
              user.present?  # All logged-in users can comment
            end

            config.permission :can_edit_tickets? do |user|
              user&.admin?  # Only admins can edit tickets
            end

            config.permission :can_access_admin? do |user|
              user&.admin?  # Only admins can access admin area
            end

            config.permission :can_access_board? do |user, board|
              true  # All users can access all boards
            end

            # Email notifications (configure ActionMailer in your app)
            config.notifications_enabled = true
            config.notification_from_email = "noreply@example.com"
            config.admin_notification_emails = []  # Add admin emails here
            config.notify_ticket_author = true
            config.notify_admins_of_new_tickets = true
            config.notify_admins_of_new_comments = true
          end
        RUBY

        create_file "config/initializers/feedback_board.rb", initializer_content
        say "Created config/initializers/feedback_board.rb", :green
      end
    end
  end
end
