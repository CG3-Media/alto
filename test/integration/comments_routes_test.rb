require "test_helper"

class CommentsRoutesTest < ActionDispatch::IntegrationTest
  def setup
    # Set host for URL generation
    host! "example.com"

    # Create test data manually (working approach - fixture system not compatible with integration tests)
    @status_set = Alto::StatusSet.create!(name: "Comments Test", is_default: true)
    @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

    @board = Alto::Board.create!(name: "Test Board", slug: "test-board", status_set: @status_set, item_label_singular: "ticket")
    @user = User.create!(email: "comments-test@example.com")
    @ticket = @board.tickets.create!(title: "Test Ticket", description: "Test", user_id: @user.id)
    @comment = @ticket.comments.create!(content: "Test comment", user_id: @user.id)

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
      User.find_by(email: "comments-test@example.com")
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

  test "comment show route does not break" do
    get "/boards/#{@board.slug}/tickets/#{@ticket.id}/comments/#{@comment.id}"
    assert_not_equal 404, response.status, "Comment show route should not return 404"
  end
end
