# Permission management concern for Alto controllers
module AltoPermissions
  extend ActiveSupport::Concern

  included do
    # Auto-detect and register permission methods from host app as helpers
    PERMISSION_METHODS = [
      :can_access_alto?, :can_submit_tickets?, :can_comment?,
      :can_vote?, :can_edit_tickets?, :can_access_admin?, :can_manage_boards?,
      :can_access_board?
    ].freeze

    # Auto-register host app permission methods as helpers
    PERMISSION_METHODS.each do |method_name|
      if defined?(::ApplicationController) &&
         (::ApplicationController.instance_methods(true).include?(method_name) ||
          ::ApplicationController.private_instance_methods(true).include?(method_name))
        helper_method method_name
      end
    end

    # Always make engine versions available as helpers too
    helper_method *PERMISSION_METHODS
  end

  # Permission methods with sensible defaults
  def can_access_alto?
    check_configured_permission(:can_access_alto?) do
      return false unless current_user
      true # Default: allow access if user is logged in
    end
  end

  def can_submit_tickets?
    check_configured_permission(:can_submit_tickets?) do
      return false unless current_user
      true # Default: allow ticket submission if user is logged in
    end
  end

  def can_comment?
    check_configured_permission(:can_comment?) do
      return false unless current_user
      true # Default: allow commenting if user is logged in
    end
  end

  def can_vote?
    check_configured_permission(:can_vote?) do
      return false unless current_user
      true # Default: allow voting if user is logged in
    end
  end

  def can_edit_tickets?
    check_configured_permission(:can_edit_tickets?) do
      return false unless current_user
      false # Default: secure by default - only admins should edit
    end
  end

  def can_access_admin?
    check_configured_permission(:can_access_admin?) do
      return false unless current_user
      false # Default: secure by default - admin access should be explicitly granted
    end
  end

  def can_manage_boards?
    check_configured_permission(:can_manage_boards?) do
      return false unless current_user
      false # Default: secure by default - board management should be explicitly granted
    end
  end

  def can_access_board?(board = nil)
    check_configured_permission(:can_access_board?, board) do
      return false unless current_user

      # Check if board is admin-only and user has admin access
      if board&.admin_only?
        return can_access_admin?
      end

      true # Default: allow access to public boards if user is logged in
    end
  end

  protected

  # Admin access check for controllers that require admin permissions
  def ensure_admin_access
    # Use the existing permission system - no test bypass
    unless can_access_admin?
      redirect_to boards_path, alert: "You do not have permission to access the admin area"
    end
  end

  private

  # Check for permission methods defined in the initializer configuration
  # Falls back to provided block if method doesn't exist in config
  def check_configured_permission(method_name, *args, &fallback_block)
    Alto::PermissionChecker.call(method_name, self, *args, &fallback_block)
  end
end
