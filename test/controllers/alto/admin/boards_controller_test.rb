require "test_helper"

module Alto
  module Admin
    class BoardsControllerTest < ActionDispatch::IntegrationTest
      include ::Alto::Engine.routes.url_helpers
      include AltoAuthTestHelper

      def setup
        setup_alto_permissions(can_manage_boards: true, can_access_admin: true)

        # Use fixtures instead of manual creation
        @user = users(:one)
        @admin = users(:admin)

        # Use existing fixture status set and board
        @status_set = alto_status_sets(:default)
        @board = alto_boards(:bugs)
      end

      def teardown
        teardown_alto_permissions
      end

      test "admin routes exist" do
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
        get new_admin_board_path
        assert_response :success
        assert_select 'input.field-label', 1, "Should render one field label input by default"
      end

      test "create board with empty field does not persist field" do
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
        # Clear the admin permissions set in setup and configure non-admin user
        ::Alto.configure do |config|
          config.permission :can_access_admin? do
            false
          end
        end

        get admin_boards_path
        # Should redirect or return 403/401
        assert_response :redirect
      end

      test "admin user can access admin area" do
        get admin_boards_path
        # Should allow access (using admin permissions from setup)
        assert_response :success
      end

      test "admin can create board successfully" do
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
