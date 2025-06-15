module AltoAuthTestHelper
  def setup_alto_permissions(can_manage_boards: false, can_access_admin: false)
    # Always start with a clean slate
    teardown_alto_permissions

    # Only stub unavoidable I/O - the permission configuration
    ::Alto.configure do |config|
      config.permission :can_access_alto? do
        true
      end

      config.permission :can_manage_boards? do
        can_manage_boards
      end

      config.permission :can_access_admin? do
        can_access_admin
      end

      config.permission :can_access_board? do |board|
        true # Allow access to all boards in tests
      end

      # Configure user_email lookup for Subscribable concern
      config.user_email do |user_id|
        user = User.find_by(id: user_id)
        user&.email
      end
    end

    # Use real user from fixtures
    user = users(:one)
    ::Alto::ApplicationController.define_method(:current_user) do
      user
    end
  end

  def teardown_alto_permissions
    # Clean up configuration completely
    ::Alto.instance_variable_set(:@configuration, nil)

    # Remove any dynamically defined methods - be more aggressive
    begin
      if ::Alto::ApplicationController.method_defined?(:current_user)
        ::Alto::ApplicationController.remove_method(:current_user)
      end
    rescue NameError
      # Method wasn't defined, that's fine
    end

    # Also check for private method
    begin
      if ::Alto::ApplicationController.private_method_defined?(:current_user)
        ::Alto::ApplicationController.remove_method(:current_user)
      end
    rescue NameError
      # Method wasn't defined, that's fine
    end

    # Reset to fresh configuration - this creates a new clean instance
    ::Alto.configure { }
  end
end
