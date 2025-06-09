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
