# FeedbackBoard Configuration
FeedbackBoard.configure do |config|
  # User model configuration
  config.user_model = "User"

  # User display name (customize for your user model)
  # config.user_display_name do |user_id|
  #   user = User.find_by(id: user_id)
  #   user&.name || user&.email || "User ##{user_id}"
  # end

  # Permission methods (customize for your authentication system)

  # Who can access the feedback board at all?
  config.permission :can_access_feedback_board? do
    user_signed_in?  # Devise helper, adjust for your auth system
  end

  # Who can submit new tickets?
  config.permission :can_submit_tickets? do
    current_user.present?
  end

  # Who can comment on tickets?
  config.permission :can_comment? do
    current_user.present?
  end

  # Who can vote on tickets and comments?
  config.permission :can_vote? do
    current_user.present?
  end

  # Who can edit any ticket? (Usually admins only)
  config.permission :can_edit_tickets? do
    current_user&.admin?
  end

  # Who can access the admin area?
  config.permission :can_access_admin? do
    current_user&.admin?
  end

  # Who can manage boards? (Create, edit, delete boards)
  config.permission :can_manage_boards? do
    current_user&.admin?
  end

  # Who can access specific boards? (board-level access control)
  # config.permission :can_access_board? do |board|
  #   case board.slug
  #   when 'internal'
  #     current_user&.staff?
  #   else
  #     current_user.present?
  #   end
  # end

  # Board configuration
  config.allow_board_deletion_with_tickets = false
end
