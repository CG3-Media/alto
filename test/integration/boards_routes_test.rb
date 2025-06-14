require "test_helper"

class BoardsRoutesTest < ActionDispatch::IntegrationTest
  def setup
    # Set host for URL generation
    host! "example.com"

    # Create test data manually (working approach - fixture system not compatible with integration tests)
    @status_set = Alto::StatusSet.create!(name: "Boards Test Status Set", is_default: true)
    @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

    @board = Alto::Board.create!(
      name: "General Discussion",
      slug: "general-discussion",
      status_set: @status_set,
      item_label_singular: "ticket"
    )

    @user = User.create!(email: "boards-test@example.com")

    # Configure Alto permissions for testing
    ::Alto.configure do |config|
      config.permission :can_access_alto? do
        true
      end
      config.permission :can_access_board? do |board|
        true
      end
      config.permission :can_comment? do
        true
      end
      config.permission :can_edit_tickets? do
        true
      end
      config.permission :can_submit_tickets? do
        true
      end
      config.permission :can_vote? do
        true
      end
    end

    # Store original method for restoration
    @original_current_user_method = Alto::ApplicationController.instance_method(:current_user) if Alto::ApplicationController.method_defined?(:current_user)

    # Override current_user for this test class only
    Alto::ApplicationController.define_method(:current_user) do
      User.find_by(email: "boards-test@example.com")
    end
  end

  def teardown
    # Restore original current_user method to prevent test interference
    if @original_current_user_method
      Alto::ApplicationController.define_method(:current_user, @original_current_user_method)
    else
      Alto::ApplicationController.remove_method(:current_user) if Alto::ApplicationController.method_defined?(:current_user)
    end
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
    # Mock admin permission
    ::Alto.configure do |config|
      config.permission :can_access_admin? do
        true
      end
    end

    get "/admin/boards/#{@board.slug}/edit"
    assert_equal 200, response.status, "Admin board edit should return 200, got #{response.status}"
  end
end
