require "test_helper"

module Alto
  class BoardsControllerTest < ActionDispatch::IntegrationTest
    include ::Alto::Engine.routes.url_helpers

    def setup
      # Create test status set
      @status_set = Alto::StatusSet.create!(name: "Test Status Set", is_default: true)
      @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

      # Create test boards
      @board = Board.create!(
        name: "Test Board",
        is_admin_only: false,
        item_label_singular: "ticket",
        status_set: @status_set
      )

      @feedback_board = Board.create!(
        name: "Feedback Board",
        slug: "feedback",
        is_admin_only: false,
        item_label_singular: "ticket",
        status_set: @status_set
      )
    end

    # Basic functionality tests
    test "should get index" do
      get boards_path
      assert_response :success
    end

    test "should redirect root to default board" do
      get "/"
      assert_response :redirect
    end

    test "board show redirects to tickets" do
      get board_path(@board)
      assert_response :redirect
      assert_redirected_to board_tickets_path(@board)
    end

    # Permission tests (should redirect without admin access)
    test "new requires admin access" do
      get new_board_path
      assert_response :redirect
    end

    test "create requires admin access" do
      post boards_path, params: { board: { name: "New Board" } }
      assert_response :redirect
    end

    test "edit requires admin access" do
      get edit_board_path(@board)
      assert_response :redirect
    end

    test "update requires admin access" do
      patch board_path(@board), params: { board: { name: "Updated" } }
      assert_response :redirect
    end

    test "destroy requires admin access" do
      delete board_path(@board)
      assert_response :redirect
    end
  end
end
