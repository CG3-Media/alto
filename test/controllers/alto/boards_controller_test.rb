require "test_helper"

module Alto
  class BoardsControllerTest < ActionDispatch::IntegrationTest
    include ::Alto::Engine.routes.url_helpers

    def setup
      # Let Rails transactional fixtures handle data isolation
      # Create test user
      @user = User.create!(email: "test@example.com")

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
    end

    test "should get index" do
      get boards_path
      assert_response :success
    end

    test "should redirect root to default board" do
      get root_path
      assert_response :redirect
    end

    test "board show redirects to tickets" do
      get board_path(@board)
      assert_response :redirect
      assert_redirected_to board_tickets_path(@board)
    end
  end
end
