require 'test_helper'

module Alto
  class BoardsControllerTest < ActionDispatch::IntegrationTest
    include ::Alto::Engine.routes.url_helpers

    def setup
      # Clear existing data
      Alto::Board.delete_all
      User.delete_all

      # Create test user
      @user = User.create!(email: 'test@example.com')

      # Create test board
      @board = Board.create!(
        name: "Test Board",
        is_admin_only: false,
        item_label_singular: "ticket"
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
