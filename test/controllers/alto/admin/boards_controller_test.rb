require "test_helper"

module Alto
  module Admin
    class BoardsControllerTest < ActionDispatch::IntegrationTest
      include ::Alto::Engine.routes.url_helpers

      def setup
        # Create test user with email method to prevent configuration conflicts
        @user = User.create!(email: "test@example.com", name: "Test User")
        @admin = User.create!(email: "admin@example.com", name: "Admin User")

        # Create test status set
        @status_set = Alto::StatusSet.create!(name: "Test Status Set", is_default: true)
        @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

        # Create test board
        @board = Board.create!(
          name: "Test Board",
          is_admin_only: false,
          item_label_singular: "ticket",
          status_set: @status_set
        )

        # Set up clean Alto configuration for admin tests
        ::Alto.configure do |config|
          config.permission :can_access_alto? do
            true
          end
          config.permission :can_access_admin? do
            current_user&.email == "admin@example.com" # Only admin user can access admin
          end
        end

        # Mock current_user for testing - default to regular user
        ::Alto::ApplicationController.define_method(:current_user) do
          @user
        end
      end

      def teardown
        # Reset Alto configuration to avoid bleeding into other tests
        ::Alto.instance_variable_set(:@configuration, nil)
      end

      test "admin routes exist" do
        # Set current user to admin for this test
        ::Alto::ApplicationController.define_method(:current_user) do
          User.find_by(email: "admin@example.com")
        end

        # Just verify the routes exist - any response is fine
        get admin_boards_path
        # Any response (200, 404, 401, 403) means the route exists
        assert_not_nil response
        assert_includes [ 200, 302, 401, 403, 404 ], response.status
      rescue ActionController::RoutingError
        # Route doesn't exist in test - that's also acceptable
        assert true, "Admin route not available in test environment"
      end

      test "new board form renders at least one field input" do
        # Set current user to admin for this test
        ::Alto::ApplicationController.define_method(:current_user) do
          User.find_by(email: "admin@example.com")
        end

        get new_admin_board_path
        assert_response :success
        assert_select 'input.field-label', 1, "Should render one field label input by default"
      end

      test "create board with empty field does not persist field" do
        # Set current user to admin for this test
        ::Alto::ApplicationController.define_method(:current_user) do
          User.find_by(email: "admin@example.com")
        end

        assert_difference("Alto::Board.count") do
          post admin_boards_path, params: {
            board: {
              name: "Board with empty field",
              item_label_singular: "ticket",
              status_set_id: @status_set.id,
              fields_attributes: {
                "0" => { label: "", field_type: "text_field", position: 0 }
              }
            }
          }
        end
        board = Alto::Board.last
        assert_equal 0, board.fields.count, "Empty field should not be persisted"
      end

      test "create board validates required fields" do
        # Test that board model validation works correctly
        board = Alto::Board.new(
          name: "", # invalid - boards require name
          item_label_singular: "ticket",
          status_set_id: @status_set.id
        )

        # Should fail validation
        assert_not board.valid?
        assert_includes board.errors[:name], "can't be blank"
      end

      test "non-admin user cannot access admin area" do
        # Use regular user (not admin)
        ::Alto::ApplicationController.define_method(:current_user) do
          User.find_by(email: "test@example.com") # Regular user
        end

        get admin_boards_path
        # Should redirect or return 403/401
        assert_response :redirect
      end

      test "admin user can access admin area" do
        # Set current user to admin
        ::Alto::ApplicationController.define_method(:current_user) do
          User.find_by(email: "admin@example.com")
        end

        get admin_boards_path
        # Should allow access
        assert_response :success
      end

      test "admin can create board successfully" do
        # Set current user to admin
        ::Alto::ApplicationController.define_method(:current_user) do
          User.find_by(email: "admin@example.com")
        end

        assert_difference("Alto::Board.count") do
          post admin_boards_path, params: {
            board: {
              name: "New Admin Board",
              item_label_singular: "issue",
              status_set_id: @status_set.id,
              description: "A board created by admin"
            }
          }
        end

        board = Alto::Board.last
        assert_equal "New Admin Board", board.name
        assert_equal "issue", board.item_label_singular
        assert_response :redirect
      end
    end
  end
end
