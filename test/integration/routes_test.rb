require "test_helper"

module Alto
  class RoutesTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
    # Minimal setup for route testing - we just need valid IDs
    @status_set = Alto::StatusSet.create!(name: "Route Test Status Set", is_default: true)
    @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

    @board = Alto::Board.create!(
      name: "Internal Issues",
      slug: "internal-issues",
      status_set: @status_set,
      item_label_singular: "ticket"
    )

    @user = User.create!(email: "route-test@example.com")
    @ticket = @board.tickets.create!(
      title: "Test Route Ticket",
      description: "For route testing",
      user_id: @user.id
    )

    # Set host for URL generation
    host! "example.com"

    # Configure Alto permissions for testing
    ::Alto.configure do |config|
      config.permission :can_access_alto? do
        true
      end
      config.permission :can_submit_tickets? do
        true
      end
      config.permission :can_access_board? do |board|
        true
      end
      config.permission :can_edit_tickets? do
        true
      end
      config.permission :can_vote? do
        true
      end
      config.permission :can_comment? do
        true
      end
    end

    # Mock current_user for testing - use User.find to ensure it exists
    user = @user
    ::Alto::ApplicationController.define_method(:current_user) do
      user
    end
  end

        # Test the specific route mentioned by user - /boards/internal-issues/tickets/470/edit
    test "boards ticket edit route returns 200 success" do
      get "/boards/internal-issues/tickets/#{@ticket.id}/edit"

      # Should not get a routing error (404) - route exists and is accessible
      assert_not_equal 404, response.status, "Edit ticket route returned 404 - route is broken!"

      # Should render the edit form successfully
      assert_equal 200, response.status, "Edit route should return 200 (success), got #{response.status}"
      assert_includes response.body, @ticket.title, "Edit form should contain ticket title"
    end

        test "boards ticket edit route handles archived tickets with 302 redirect" do
      # Archive the ticket to test redirect behavior
      @ticket.update!(archived: true)

      get "/boards/internal-issues/tickets/#{@ticket.id}/edit"

      # Should redirect when ticket is archived (can't edit archived tickets)
      assert_equal 302, response.status, "Edit route should return 302 (redirect) for archived tickets"

      # Follow redirect to see where it goes
      follow_redirect!
      assert_equal 200, response.status, "Redirect should lead to 200 success"
    end

        # Test core ticket routes return 200 success
    test "critical ticket routes return 200 success" do
      # Board tickets index - main landing page - should always return 200
      get "/boards/internal-issues/tickets"
      assert_equal 200, response.status, "Tickets index should return 200, got #{response.status}"
      assert_includes response.body, @ticket.title, "Tickets index should show ticket titles"

      # Ticket show - individual ticket view - should always return 200
      get "/boards/internal-issues/tickets/#{@ticket.id}"
      assert_equal 200, response.status, "Ticket show should return 200, got #{response.status}"
      assert_includes response.body, @ticket.title, "Ticket show should display ticket title"
      assert_includes response.body, @ticket.description, "Ticket show should display ticket description"

      # New ticket form - should always return 200
      get "/boards/internal-issues/tickets/new"
      assert_equal 200, response.status, "New ticket form should return 200, got #{response.status}"
      assert_includes response.body, "New", "New ticket page should have 'New' in content"
    end

        # Test board navigation routes - 200 success
    test "boards index returns 200 success" do
      # Boards index should always return 200
      get "/boards"
      assert_equal 200, response.status, "Boards index should return 200, got #{response.status}"
      assert_includes response.body, @board.name, "Boards index should show board names"
    end

    # Test board navigation routes - 302 redirect
    test "individual board returns 302 redirect" do
      # Individual board should always redirect to tickets (302)
      get "/boards/internal-issues"
      assert_equal 302, response.status, "Board show should return 302 redirect, got #{response.status}"

      # Follow the redirect and ensure it goes to tickets
      follow_redirect!
      assert_equal 200, response.status, "Redirect should lead to 200 success"
      assert_includes request.path, "/tickets", "Should redirect to tickets path"
    end

        # Test that routes work with different board slug formats - 200 success
    test "complex board slugs return 200 success" do
      bug_board = Alto::Board.create!(
        name: "Bug Reports & Issues",
        slug: "bug-reports-issues",
        status_set: @status_set,
        item_label_singular: "bug"
      )

      bug_ticket = bug_board.tickets.create!(
        title: "Sample Bug",
        description: "Test",
        user_id: @user.id
      )

      # Test complex slug in edit route - should return 200
      get "/boards/bug-reports-issues/tickets/#{bug_ticket.id}/edit"
      assert_equal 200, response.status, "Complex slug edit route should return 200, got #{response.status}"
      assert_includes response.body, bug_ticket.title, "Edit form should contain bug ticket title"

      # Test complex slug in tickets index - should return 200
      get "/boards/bug-reports-issues/tickets"
      assert_equal 200, response.status, "Complex slug tickets index should return 200, got #{response.status}"
      assert_includes response.body, bug_ticket.title, "Tickets index should show bug ticket"
    end

        # Test form submission with valid data - should return 302 redirect
    test "ticket creation with valid data returns 302 redirect" do
      assert_difference("Alto::Ticket.count", 1) do
        post "/boards/internal-issues/tickets", params: {
          ticket: {
            title: "Route Test Ticket",
            description: "Testing route accessibility"
          }
        }
      end

      # Should redirect after successful creation
      assert_equal 302, response.status, "Ticket creation should return 302 redirect, got #{response.status}"

      # Follow redirect to verify it goes to the new ticket
      follow_redirect!
      assert_equal 200, response.status, "Redirect should lead to 200 success"
      assert_includes response.body, "Route Test Ticket", "Should redirect to new ticket page"
    end

    # Test form submission with invalid data - should return 200 with errors
    test "ticket creation with invalid data returns 200 with errors" do
      assert_no_difference("Alto::Ticket.count") do
        post "/boards/internal-issues/tickets", params: {
          ticket: {
            title: "", # Invalid - blank title
            description: "Testing validation errors"
          }
        }
      end

      # Should return 200 to show form with validation errors
      assert_equal 200, response.status, "Invalid ticket creation should return 200, got #{response.status}"
      assert_includes response.body, "form", "Should show form for corrections"
    end

            # Test that the routes exist and can be resolved (confirmed by the other tests passing)
  end
end
