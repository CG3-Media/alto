require "test_helper"

module FeedbackBoard
  class UpvotesControllerTest < ActionDispatch::IntegrationTest
    include ::FeedbackBoard::Engine.routes.url_helpers
    def setup
      # Setup test database tables
      ::FeedbackBoard::DatabaseSetup.force_setup!

      # Create a status set with statuses
      @status_set = ::FeedbackBoard::StatusSet.create!(
        name: 'Test Status Set',
        is_default: true
      )
      @status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')

      @board = ::FeedbackBoard::Board.create!(
        name: "Test Board",
        slug: "test-board",
        status_set: @status_set
      )

      @ticket = @board.tickets.create!(
        title: "Test Ticket",
        description: "Description",
        user_id: 1
      )

      @comment = @ticket.comments.create!(
        content: "Test comment",
        user_id: 2
      )

      # Configure FeedbackBoard to allow all access for testing
      ::FeedbackBoard.configure do |config|
        config.permission :can_access_feedback_board? do
          true
        end
        config.permission :can_vote? do
          true
        end
      end

      # Create a mock current_user helper for testing
      ::FeedbackBoard::ApplicationController.define_method(:current_user) do
        Struct.new(:id).new(1)
      end
    end

    # 🚨 CRITICAL BUG TEST: Removing comment upvote should NOT delete ticket
    test "removing comment upvote should NOT delete the ticket" do
      # Create an upvote on the comment
      upvote = @comment.upvotes.create!(user_id: 1)

      # Verify initial state
      assert @ticket.persisted?, "Ticket should exist before test"
      assert @comment.persisted?, "Comment should exist before test"
      assert upvote.persisted?, "Upvote should exist before test"
      assert_equal 1, @comment.upvotes.count, "Comment should have 1 upvote"

      # Record initial counts
      initial_ticket_count = ::FeedbackBoard::Ticket.count
      initial_comment_count = ::FeedbackBoard::Comment.count
      initial_upvote_count = ::FeedbackBoard::Upvote.count

      # Remove the upvote using DELETE request (like the UI would)
      delete "/feedback/comments/#{@comment.id}/upvotes/#{upvote.id}"

            # CRITICAL ASSERTIONS: Verify ticket and comment still exist!
      assert ::FeedbackBoard::Ticket.exists?(@ticket.id), "🚨 BUG: Ticket was deleted when removing comment upvote!"
      assert ::FeedbackBoard::Comment.exists?(@comment.id), "🚨 BUG: Comment was deleted when removing upvote!"

      # Verify only the upvote was removed
      assert_not ::FeedbackBoard::Upvote.exists?(upvote.id), "Upvote should be deleted"
      assert_equal initial_ticket_count, ::FeedbackBoard::Ticket.count, "Ticket count should be unchanged"
      assert_equal initial_comment_count, ::FeedbackBoard::Comment.count, "Comment count should be unchanged"
      assert_equal initial_upvote_count - 1, ::FeedbackBoard::Upvote.count, "Only upvote should be removed"

      # Refresh objects to verify they still exist
      @ticket.reload
      @comment.reload
      assert_equal "Test Ticket", @ticket.title, "Ticket data should be intact"
      assert_equal "Test comment", @comment.content, "Comment data should be intact"
    end

    # Test using toggle action (which is what the UI actually uses)
    test "toggling comment upvote off should NOT delete the ticket" do
      # Create an upvote on the comment
      upvote = @comment.upvotes.create!(user_id: 1)

      # Verify initial state
      assert @ticket.persisted?, "Ticket should exist before test"
      assert @comment.persisted?, "Comment should exist before test"
      assert_equal 1, @comment.upvotes.count, "Comment should have 1 upvote"

      # Record initial counts
      initial_ticket_count = ::FeedbackBoard::Ticket.count
      initial_comment_count = ::FeedbackBoard::Comment.count

      # Toggle the upvote off using DELETE request to toggle endpoint
      delete "/feedback/comments/#{@comment.id}/upvotes/toggle"

            # CRITICAL ASSERTIONS: Verify ticket and comment still exist!
      assert ::FeedbackBoard::Ticket.exists?(@ticket.id), "🚨 BUG: Ticket was deleted when toggling comment upvote off!"
      assert ::FeedbackBoard::Comment.exists?(@comment.id), "🚨 BUG: Comment was deleted when toggling upvote off!"

      # Verify counts are correct
      assert_equal initial_ticket_count, ::FeedbackBoard::Ticket.count, "Ticket count should be unchanged"
      assert_equal initial_comment_count, ::FeedbackBoard::Comment.count, "Comment count should be unchanged"
      assert_equal 0, @comment.upvotes.count, "Comment should have 0 upvotes after toggle"

      # Refresh objects to verify they still exist
      @ticket.reload
      @comment.reload
      assert_equal "Test Ticket", @ticket.title, "Ticket data should be intact"
      assert_equal "Test comment", @comment.content, "Comment data should be intact"
    end

    # Test AJAX request (JSON response)
    test "removing comment upvote via AJAX should NOT delete ticket" do
      upvote = @comment.upvotes.create!(user_id: 1)

      initial_ticket_count = ::FeedbackBoard::Ticket.count
      initial_comment_count = ::FeedbackBoard::Comment.count

      # Make AJAX request to toggle endpoint
      delete "/feedback/comments/#{@comment.id}/upvotes/toggle",
             headers: { 'Accept' => 'application/json' }

      # Should return JSON response
      assert_response :success
      json_response = JSON.parse(response.body)
      assert json_response.key?('upvoted'), "Should return upvoted status"
      assert json_response.key?('upvotes_count'), "Should return vote count"
      assert_equal false, json_response['upvoted'], "Should show not upvoted"
      assert_equal 0, json_response['upvotes_count'], "Should show 0 votes"

      # CRITICAL: Verify entities still exist
      assert ::FeedbackBoard::Ticket.exists?(@ticket.id), "🚨 BUG: Ticket deleted in AJAX upvote removal!"
      assert ::FeedbackBoard::Comment.exists?(@comment.id), "🚨 BUG: Comment deleted in AJAX upvote removal!"
      assert_equal initial_ticket_count, ::FeedbackBoard::Ticket.count, "Ticket count unchanged"
      assert_equal initial_comment_count, ::FeedbackBoard::Comment.count, "Comment count unchanged"
    end

    # Test URL generation to make sure routes are correct
    test "comment upvote URLs should be correctly generated" do
      # Test toggle path generation
      toggle_path = toggle_comment_upvotes_path(@comment)
      expected_path = "/feedback/comments/#{@comment.id}/upvotes/toggle"
      assert_equal expected_path, toggle_path, "Toggle path should be correct"

      # Test individual upvote path
      upvote = @comment.upvotes.create!(user_id: 1)
      delete_path = comment_upvote_path(@comment, upvote)
      expected_delete_path = "/feedback/comments/#{@comment.id}/upvotes/#{upvote.id}"
      assert_equal expected_delete_path, delete_path, "Delete path should be correct"
    end

    # Test that the controller is finding the right upvotable
    test "controller should find comment not ticket when processing comment upvote" do
      upvote = @comment.upvotes.create!(user_id: 1)

            # Spy on the controller to see what @upvotable gets set to
      original_method = ::FeedbackBoard::UpvotesController.instance_method(:set_board_and_upvotable)
      upvotable_spy = nil

      ::FeedbackBoard::UpvotesController.define_method(:set_board_and_upvotable) do
        original_method.bind(self).call
        upvotable_spy = @upvotable
      end

      delete "/feedback/comments/#{@comment.id}/upvotes/toggle"

      # Restore original method
      ::FeedbackBoard::UpvotesController.define_method(:set_board_and_upvotable, original_method)

      assert_instance_of ::FeedbackBoard::Comment, upvotable_spy, "Controller should identify comment as upvotable"
      assert_equal @comment.id, upvotable_spy.id, "Controller should find the correct comment"
      assert_equal @comment, upvotable_spy, "Controller should find the exact comment object"
    end

    # Test comment upvote functionality
    test "should handle comment upvote via DELETE request" do
      # Create an upvote first
      upvote = @comment.upvotes.create!(user_id: 1)

      # Verify the route exists by attempting to generate the path
      delete_path = "/feedback/comments/#{@comment.id}/upvotes/#{upvote.id}"

      # Make the request
      delete delete_path

      # Should redirect (even if there are authentication issues, the route should exist)
      assert_response :redirect
    end

    test "should handle comment upvote via POST request" do
      post_path = "/feedback/comments/#{@comment.id}/upvotes"

      # Make the request
      post post_path, params: { user_id: 1 }

      # Should redirect (even if there are authentication issues, the route should exist)
      assert_response :redirect
    end

    # Test the route mappings specifically
    test "comment upvote routes should be properly mapped" do
      # Test POST route
      assert_recognizes(
        { controller: 'feedback_board/upvotes', action: 'create', comment_id: '1' },
        { path: '/feedback/comments/1/upvotes', method: :post }
      )

      # Test DELETE route
      assert_recognizes(
        { controller: 'feedback_board/upvotes', action: 'destroy', comment_id: '1', id: '1' },
        { path: '/feedback/comments/1/upvotes/1', method: :delete }
      )
    end

        # Test that the original error route is fixed
    test "DELETE without upvote ID should return 404" do
      # DELETE "/comments/1/upvotes" without an ID should not have a matching route
      # This proves the original routing error is fixed

      delete "/feedback/comments/#{@comment.id}/upvotes"
      # Should get 404 because there's no DELETE route without an upvote ID
      assert_response :not_found
    end

    # Test upvote model functionality
    test "should create and destroy comment upvotes" do
      # Test creation
      initial_count = @comment.upvotes.count
      upvote = @comment.upvotes.create!(user_id: 1)

      assert_equal initial_count + 1, @comment.upvotes.count
      assert_equal 1, upvote.user_id
      assert_equal @comment, upvote.upvotable

      # Test destruction
      upvote.destroy
      assert_equal initial_count, @comment.upvotes.count
    end

    test "should enforce upvote uniqueness per user" do
      # Create first upvote
      @comment.upvotes.create!(user_id: 1)

      # Try to create duplicate
      duplicate = @comment.upvotes.build(user_id: 1)
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:user_id], "has already been taken"
    end
  end
end
