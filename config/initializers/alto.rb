# Alto Configuration for Testing
Alto.configure do |config|
  # User model configuration
  config.user_model = "User"

  # User profile avatar URL example (commented out for testing)
  # config.user_profile_avatar_url do |user_id|
  #   user = User.find_by(id: user_id)
  #   user&.avatar&.url  # Adjust for your avatar method
  # end

  # Permission methods - all allow access for testing
  config.permission :can_access_alto? do
    true  # Allow all access for testing
  end

  config.permission :can_submit_tickets? do
    true
  end

  config.permission :can_comment? do
    true
  end

  config.permission :can_vote? do
    true
  end

  config.permission :can_edit_tickets? do
    true  # Allow all for testing
  end

  config.permission :can_access_admin? do
    true  # Allow all for testing
  end

  config.permission :can_manage_boards? do
    true  # Allow all for testing
  end

  # Board configuration
  config.allow_board_deletion_with_tickets = false

  # Image uploads (requires ActiveStorage setup)
  # config.image_uploads_enabled = true
end
