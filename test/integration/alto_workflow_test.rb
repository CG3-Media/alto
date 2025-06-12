require "test_helper"

class AltoWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    # Setup test database tables
    ::Alto::DatabaseSetup.force_setup!

    # Create test users since fixtures aren't loaded after force_setup
    @user1 = User.find_or_create_by!(id: 1) { |u| u.email = "test1@example.com" }
    @user2 = User.find_or_create_by!(id: 2) { |u| u.email = "test2@example.com" }
    @user3 = User.find_or_create_by!(id: 3) { |u| u.email = "test3@example.com" }
    @user4 = User.find_or_create_by!(id: 4) { |u| u.email = "test4@example.com" }
    @user5 = User.find_or_create_by!(id: 5) { |u| u.email = "test5@example.com" }

    # Create a status set with statuses
    @status_set = ::Alto::StatusSet.create!(
      name: "Test Workflow Status Set",
      description: "For integration testing",
      is_default: true
    )

    @status_set.statuses.create!([
      { name: "Open", color: "green", position: 0, slug: "open" },
      { name: "In Progress", color: "yellow", position: 1, slug: "in_progress" },
      { name: "Closed", color: "gray", position: 2, slug: "closed" }
    ])
  end

  test "complete feedback board workflow" do
    # 1. Create a board (use unique name to avoid fixture collision)
    board = Alto::Board.create!(
      name: "Workflow Test Board",
      description: "Submit your feature ideas here",
      status_set: @status_set,
      item_label_singular: "feature"
    )

    assert board.persisted?
    assert_equal "workflow-test-board", board.slug
    assert board.has_status_tracking?

    # 2. Create a ticket
    ticket = board.tickets.create!(
      title: "Add dark mode",
      description: "It would be great to have a dark mode option for better accessibility.",
      user_id: 1
    )

    assert ticket.persisted?
    assert_equal "open", ticket.status_slug
    assert_equal board, ticket.board
    assert_not ticket.locked?

    # 3. Add some upvotes to the ticket
    upvote1 = ticket.upvotes.create!(user_id: 2)
    upvote2 = ticket.upvotes.create!(user_id: 3)

    assert_equal 2, ticket.upvotes_count
    assert ticket.upvoted_by?(Struct.new(:id).new(2))
    assert_not ticket.upvoted_by?(Struct.new(:id).new(4))

    # 4. Add a comment to the ticket
    comment = ticket.comments.create!(
      content: "Great idea! I would definitely use this feature.",
      user_id: 2
    )

    assert comment.persisted?
    assert_equal 0, comment.depth  # Top-level comment
    assert_not comment.is_reply?
    assert comment.can_be_replied_to?

    # 5. Add upvotes to the comment
    comment_upvote = comment.upvotes.create!(user_id: 3)

    assert_equal 1, comment.upvotes_count
    assert comment.upvoted_by?(Struct.new(:id).new(3))

    # 6. Add a reply to the comment
    reply = ticket.comments.create!(
      content: "I agree! This would be very helpful for night-time usage.",
      user_id: 4,
      parent: comment
    )

    assert reply.persisted?
    assert_equal 1, reply.depth
    assert reply.is_reply?
    assert_equal comment, reply.parent
    assert reply.can_be_replied_to?

    # 7. Add a nested reply
    nested_reply = ticket.comments.create!(
      content: "Yes, and it should also reduce eye strain.",
      user_id: 5,
      parent: reply
    )

    assert nested_reply.persisted?
    assert_equal 2, nested_reply.depth
    assert_equal comment, nested_reply.thread_root
    assert_not nested_reply.can_be_replied_to?  # Max depth reached

    # 8. Verify comment threading structure
    threaded_comments = Alto::Comment.threaded_for_ticket(ticket)

    assert_equal 1, threaded_comments.length  # One top-level comment

    thread = threaded_comments.first
    assert_equal comment, thread[:comment]
    assert_equal 1, thread[:replies].length

    reply_thread = thread[:replies].first
    assert_equal reply, reply_thread[:comment]
    assert_equal 1, reply_thread[:replies].length
    assert_equal nested_reply, reply_thread[:replies].first[:comment]

    # 9. Update ticket status
    ticket.update!(status_slug: "in-progress")

    assert_equal "in-progress", ticket.status_slug
    assert_equal "In Progress", ticket.status_name

    # 10. Lock the ticket
    ticket.update!(locked: true)

    assert ticket.locked?
    assert_not ticket.can_be_voted_on?
    assert_not ticket.can_be_commented_on?
    assert_not comment.can_be_voted_on?
    assert_not comment.can_be_replied_to?

    # 11. Verify final counts
    assert_equal 1, board.tickets.count
    assert_equal 3, ticket.comments.count
    assert_equal 2, ticket.upvotes.count
    assert_equal 1, comment.upvotes.count

    # 12. Test board scoping
    tickets_for_board = Alto::Ticket.for_board(board)
    assert_includes tickets_for_board, ticket

    # 13. Test status filtering
    in_progress_tickets = Alto::Ticket.by_status("in-progress")
    assert_includes in_progress_tickets, ticket

    open_tickets = Alto::Ticket.by_status("open")
    assert_not_includes open_tickets, ticket
  end

  test "board without status tracking workflow" do
    # Create board with empty status set (no statuses) instead of nil
    empty_status_set = ::Alto::StatusSet.create!(
      name: "Empty Status Set",
      description: "No statuses for testing"
    )

    simple_board = Alto::Board.create!(
      name: "Simple Discussion",
      description: "Basic discussion board",
      status_set: empty_status_set,
      item_label_singular: "discussion"
    )

    assert_not simple_board.has_status_tracking?
    assert_empty simple_board.available_statuses

    # Create ticket on board without status tracking
    ticket = simple_board.tickets.create!(
      title: "General question",
      description: "How do I use this feature?",
      user_id: 1,
      status_slug: nil
    )

    assert ticket.persisted?
    assert_nil ticket.status_slug
    assert_equal "Unknown", ticket.status_name
    assert_not ticket.can_change_status?

    # Comments and upvotes should still work
    comment = ticket.comments.create!(
      content: "Here's how to do it...",
      user_id: 2
    )

    upvote = ticket.upvotes.create!(user_id: 3)

    assert comment.persisted?
    assert upvote.persisted?
    assert_equal 1, ticket.comments.count
    assert_equal 1, ticket.upvotes.count
  end

  test "search functionality" do
    board = Alto::Board.create!(
      name: "Search Test Board",
      status_set: @status_set,
      item_label_singular: "feature"
    )

    # Create tickets with different content
    ticket1 = board.tickets.create!(
      title: "Dark mode implementation",
      description: "Add dark theme support to the application",
      user_id: 1
    )

    ticket2 = board.tickets.create!(
      title: "Light theme improvements",
      description: "Enhance the existing light theme colors",
      user_id: 2
    )

    ticket3 = board.tickets.create!(
      title: "User preferences",
      description: "Allow users to save their preferred settings",
      user_id: 3
    )

    # Add comment with searchable content
    ticket1.comments.create!(
      content: "This should include automatic dark mode based on system preferences",
      user_id: 4
    )

    # Test title search
    dark_results = Alto::Ticket.search("dark")
    assert_includes dark_results, ticket1
    assert_not_includes dark_results, ticket2

    # Test description search
    theme_results = Alto::Ticket.search("theme")
    assert_includes theme_results, ticket1
    assert_includes theme_results, ticket2
    assert_not_includes theme_results, ticket3

    # Test comment search
    preferences_results = Alto::Ticket.search("preferences")
    assert_includes preferences_results, ticket1  # Found in comment
    assert_includes preferences_results, ticket3  # Found in title
    assert_not_includes preferences_results, ticket2

    # Test case insensitive search
    case_results = Alto::Ticket.search("DARK")
    assert_includes case_results, ticket1
  end

  test "upvote uniqueness and deletion" do
    board = Alto::Board.create!(
      name: "Vote Test",
      status_set: @status_set,
      item_label_singular: "feature"
    )
    ticket = board.tickets.create!(title: "Vote Test", description: "Test", user_id: 1)

    # Create upvote
    upvote = ticket.upvotes.create!(user_id: 2)
    assert_equal 1, ticket.upvotes.count

    # Try to create duplicate - should fail
    duplicate = ticket.upvotes.build(user_id: 2)
    assert_not duplicate.valid?

    # Delete upvote
    upvote.destroy
    assert_equal 0, ticket.upvotes.count

    # Should be able to upvote again after deletion
    new_upvote = ticket.upvotes.create!(user_id: 2)
    assert new_upvote.persisted?
    assert_equal 1, ticket.upvotes.count
  end
end
