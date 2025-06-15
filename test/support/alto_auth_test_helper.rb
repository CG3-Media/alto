module AltoAuthTestHelper
  def setup_alto_permissions(can_manage_boards: false, can_access_admin: false)
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
    end

    # Use real user from fixtures
    user = users(:one)
    ::Alto::ApplicationController.define_method(:current_user) do
      user
    end
  end

  def teardown_alto_permissions
    # Clean up between tests
    ::Alto.instance_variable_set(:@configuration, nil)
  end
end
