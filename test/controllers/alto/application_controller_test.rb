require "test_helper"

module Alto
  class ApplicationControllerTest < ActionController::TestCase
    # Don't include AltoAuthTestHelper - this test checks clean defaults
    class MockUser
      attr_accessor :id, :email, :admin

      def initialize(id: 1, email: "test@example.com", admin: false)
        @id = id
        @email = email
        @admin = admin
      end

      def admin?
        @admin
      end
    end

    class TestController < ApplicationController
      # Make private methods public for testing
      public :can_access_alto?, :can_submit_tickets?, :can_comment?,
             :can_vote?, :can_edit_tickets?, :can_access_admin?, :can_manage_boards?,
             :can_access_board?

      # Override current_user for testing - bypass parent's current_user logic
      def current_user
        @test_user
      end

      def set_test_user(user)
        @test_user = user
      end

      # Bypass authenticate_user! for testing
      private

      def authenticate_user!
        # Skip authentication in tests
      end

      def check_alto_access!
        # Skip access check in tests
      end

      # Override check_configured_permission to always use fallback for this test
      def check_configured_permission(method_name, *args, &fallback_block)
        # Force use of fallback block to test default behavior
        fallback_block.call
      end
    end

    def setup
      # Store original configuration to restore later
      @original_configuration = ::Alto.instance_variable_get(:@configuration)

      # Ensure completely clean slate - clear any global permissions
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear

      @controller = TestController.new
      @user = MockUser.new
      @board = Board.new(id: 1, name: "Test Board", slug: "test")

      # Don't set up any permissions - use defaults
    end

    def teardown
      # Restore original configuration to prevent test pollution
      ::Alto.instance_variable_set(:@configuration, @original_configuration)
    end

    test "permission methods exist and are callable" do
      # Ensure completely clean state for this test
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear
      @controller.set_test_user(@user)

      # Test that all permission methods exist and can be called
      assert_respond_to @controller, :can_access_alto?
      assert_respond_to @controller, :can_submit_tickets?
      assert_respond_to @controller, :can_comment?
      assert_respond_to @controller, :can_vote?
      assert_respond_to @controller, :can_edit_tickets?
      assert_respond_to @controller, :can_access_admin?
      assert_respond_to @controller, :can_manage_boards?
      assert_respond_to @controller, :can_access_board?
    end

    test "can_access_board? exists and works with board parameter" do
      # Ensure completely clean state for this test
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear
      @controller.set_test_user(@user)

      # This is the critical test - can_access_board? should exist
      assert_nothing_raised do
        result = @controller.can_access_board?(@board)
        assert_equal true, result, "can_access_board? should default to true"
      end
    end

    test "can_access_board? works with nil board" do
      # Ensure completely clean state for this test
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear
      @controller.set_test_user(@user)

      assert_nothing_raised do
        result = @controller.can_access_board?(nil)
        assert_equal true, result, "can_access_board? should handle nil board"
      end
    end

    test "default permission values when user exists" do
      # Ensure clean state for this test
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear
      @controller.set_test_user(@user)

      # Test default values
      assert_equal true, @controller.can_access_alto?
      assert_equal true, @controller.can_submit_tickets?
      assert_equal true, @controller.can_comment?
      assert_equal true, @controller.can_vote?
      assert_equal false, @controller.can_edit_tickets? # Secure by default
      assert_equal false, @controller.can_access_admin? # Secure by default
      assert_equal false, @controller.can_manage_boards? # Secure by default
      assert_equal true, @controller.can_access_board?(@board) # Open by default
    end

    test "admin permissions work correctly" do
      # Ensure clean state for this test
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear
      admin_user = MockUser.new(admin: true)
      @controller.set_test_user(admin_user)

      # Admin should have same defaults since we don't check admin in default implementation
      assert_equal true, @controller.can_access_alto?
      assert_equal true, @controller.can_submit_tickets?
      assert_equal true, @controller.can_comment?
      assert_equal true, @controller.can_vote?
      assert_equal false, @controller.can_edit_tickets? # Still false without main app override
      assert_equal false, @controller.can_access_admin? # Still false without main app override
      assert_equal false, @controller.can_manage_boards? # Still false without main app override
      assert_equal true, @controller.can_access_board?(@board)
    end

    test "method inheritance chain is working" do
      # Ensure completely clean state for this test
      ::Alto.instance_variable_set(:@configuration, nil)
      ::Alto.configuration.permission_methods.clear

      # Verify that ApplicationController methods are available to subclasses
      tickets_controller = TicketsController.new

      assert_respond_to tickets_controller, :can_access_board?
      assert_respond_to tickets_controller, :can_edit_tickets?
    end
  end
end
