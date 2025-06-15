require "test_helper"

class BoardsRoutesTest < ActionDispatch::IntegrationTest
  include AltoAuthTestHelper

  def setup
    # Set host for URL generation
    host! "example.com"

    # Create test data
    @status_set = Alto::StatusSet.create!(name: "Boards Test Status Set", is_default: true)
    @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

    @board = Alto::Board.create!(
      name: "General Discussion",
      slug: "general-discussion",
      status_set: @status_set,
      item_label_singular: "ticket"
    )

    @user = User.create!(email: "boards-test@example.com")

    # Use the standard test helper for permissions
    setup_alto_permissions(can_manage_boards: true, can_access_admin: true)
  end

  def teardown
    teardown_alto_permissions
  end

  # Test boards index - should return 200 success
  test "boards index returns 200 success" do
    get "/boards"
    assert_equal 200, response.status, "Boards index should return 200, got #{response.status}"
  end

  # Test individual board - should redirect to tickets (302)
  test "board show redirects to tickets with 302" do
    get "/boards/#{@board.slug}"
    assert_equal 302, response.status, "Board show should return 302 redirect, got #{response.status}"

    # Follow redirect to ensure it leads to 200 success
    follow_redirect!
    assert_equal 200, response.status, "Redirect should lead to 200 success"
  end

  # Test admin routes
  test "admin board access returns 200 success" do
    get "/admin/boards/#{@board.slug}/edit"
    assert_equal 200, response.status, "Admin board edit should return 200, got #{response.status}"
  end
end
