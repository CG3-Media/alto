require "test_helper"

module Alto
  class ApplicationControllerAdminTest < ActionController::TestCase
    class TestController < Alto::ApplicationController
      # Make can_access_board? method public for testing
      public :can_access_board?, :can_access_admin?

      # Override current_user for testing
      attr_accessor :test_user, :test_admin_status

      def current_user
        @test_user
      end

      def can_access_admin?
        @test_admin_status || false
      end

      # Bypass other auth checks for testing
      private

      def authenticate_user!
        # Skip authentication in tests
      end

      def check_alto_access!
        # Skip access check in tests
      end
    end

    def setup
      @controller = TestController.new

      # Create test status set
      @status_set = Alto::StatusSet.create!(name: "Test Status Set", is_default: true)
      @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

      @public_board = Board.create!(
        name: "Public Board",
        is_admin_only: false,
        status_set: @status_set,
        item_label_singular: "ticket"
      )
      @admin_board = Board.create!(
        name: "Admin Board",
        is_admin_only: true,
        status_set: @status_set,
        item_label_singular: "ticket"
      )
      @user = double("user", id: 1)
    end

    test "regular user can access public boards" do
      @controller.test_user = @user
      @controller.test_admin_status = false

      assert @controller.can_access_board?(@public_board)
    end

    test "regular user cannot access admin-only boards" do
      @controller.test_user = @user
      @controller.test_admin_status = false

      assert_not @controller.can_access_board?(@admin_board)
    end

    test "admin user can access public boards" do
      @controller.test_user = @user
      @controller.test_admin_status = true

      assert @controller.can_access_board?(@public_board)
    end

    test "admin user can access admin-only boards" do
      @controller.test_user = @user
      @controller.test_admin_status = true

      assert @controller.can_access_board?(@admin_board)
    end

    test "can_access_board? returns false when no user" do
      @controller.test_user = nil
      @controller.test_admin_status = false

      assert_not @controller.can_access_board?(@public_board)
      assert_not @controller.can_access_board?(@admin_board)
    end

    test "can_access_board? handles nil board gracefully" do
      @controller.test_user = @user
      @controller.test_admin_status = false

      # Should return true for nil board if user is logged in (but not crash)
      assert @controller.can_access_board?(nil)
    end

    private

    def double(name, attributes = {})
      obj = Object.new
      attributes.each do |key, value|
        obj.define_singleton_method(key) { value }
      end
      obj
    end
  end
end
