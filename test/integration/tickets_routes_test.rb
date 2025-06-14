require "test_helper"

class TicketsRoutesTest < ActionDispatch::IntegrationTest
  def setup
    # Set host for URL generation
    host! "example.com"

    # Create test data manually (working approach - fixture system not compatible with integration tests)
    @status_set = Alto::StatusSet.create!(name: "Tickets Test Status Set", is_default: true)
    @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")
    @status_set.statuses.create!(name: "Closed", color: "red", position: 1, slug: "closed")

    @board = Alto::Board.create!(
      name: "Internal Issues",
      slug: "internal-issues",
      status_set: @status_set,
      item_label_singular: "ticket"
    )

    @user = User.create!(email: "tickets-test@example.com")

    @ticket = @board.tickets.create!(
      title: "Test Issue",
      description: "Testing ticket routes",
      user_id: @user.id
    )

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
      User.find_by(email: "tickets-test@example.com")
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

  # Test the original route mentioned by user - should return 200 success
  test "ticket edit route returns 200 success" do
    get "/boards/internal-issues/tickets/#{@ticket.id}/edit"
    assert_equal 200, response.status, "Ticket edit should return 200, got #{response.status}"
  end

  # Test tickets index - should return 200 success
  test "tickets index returns 200 success" do
    get "/boards/internal-issues/tickets"
    assert_equal 200, response.status, "Tickets index should return 200, got #{response.status}"
  end

  # Test ticket show - should return 200 success
  test "ticket show returns 200 success" do
    get "/boards/internal-issues/tickets/#{@ticket.id}"
    assert_equal 200, response.status, "Ticket show should return 200, got #{response.status}"
  end

  # Test new ticket form - should return 200 success
  test "new ticket form returns 200 success" do
    get "/boards/internal-issues/tickets/new"
    assert_equal 200, response.status, "New ticket form should return 200, got #{response.status}"
  end

  # Test ticket creation - should return 302 redirect on success
  test "ticket creation returns 302 redirect" do
    post "/boards/internal-issues/tickets", params: {
      ticket: {
        title: "New Test Ticket",
        description: "Created via integration test"
      }
    }
    assert_equal 302, response.status, "Ticket creation should return 302 redirect, got #{response.status}"

    # Follow redirect to ensure it works
    follow_redirect!
    assert_equal 200, response.status, "Redirect should lead to 200 success"
  end

  # Test admin access to tickets
  test "admin board access returns 200 success" do
    # Mock admin permission
    ::Alto.configure do |config|
      config.permission :can_access_admin? do
        true
      end
    end

    # Admin accesses tickets via board management
    get "/admin/boards/#{@board.slug}/edit"
    assert_equal 200, response.status, "Admin board edit should return 200, got #{response.status}"
  end
end
