require "test_helper"

module FeedbackBoard
  class TicketTest < ActiveSupport::TestCase
    def setup
      # Create test board with status set
      @status_set = ::FeedbackBoard::StatusSet.create!(
        name: 'Test Status Set',
        is_default: true
      )
      @status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')
      @status_set.statuses.create!(name: 'Closed', color: 'gray', position: 1, slug: 'closed')

      @board = Board.create!(
        name: "Test Board",
        status_set: @status_set
      )
    end

    test "should create ticket with valid attributes" do
      ticket = Ticket.new(
        title: "Test Ticket",
        description: "A test ticket description",
        user_id: 1,
        board: @board
      )

      assert ticket.valid?
      assert ticket.save
      assert_equal 'open', ticket.status_slug
    end

    test "should require title" do
      ticket = Ticket.new(
        description: "No title",
        user_id: 1,
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:title], "can't be blank"
    end

    test "should require description" do
      ticket = Ticket.new(
        title: "Title Only",
        user_id: 1,
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:description], "can't be blank"
    end

    test "should require user_id" do
      ticket = Ticket.new(
        title: "Test Ticket",
        description: "Description",
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:user_id], "can't be blank"
    end

    test "should belong to board" do
      ticket = Ticket.create!(
        title: "Board Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_equal @board, ticket.board
    end

    test "should have many comments" do
      ticket = Ticket.create!(
        title: "Ticket with Comments",
        description: "Description",
        user_id: 1,
        board: @board
      )

      comment1 = ticket.comments.create!(content: "First comment", user_id: 1)
      comment2 = ticket.comments.create!(content: "Second comment", user_id: 2)

      assert_equal 2, ticket.comments.count
      assert_includes ticket.comments, comment1
      assert_includes ticket.comments, comment2
    end

    test "should have many upvotes" do
      ticket = Ticket.create!(
        title: "Upvoted Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      upvote1 = ticket.upvotes.create!(user_id: 1)
      upvote2 = ticket.upvotes.create!(user_id: 2)

      assert_equal 2, ticket.upvotes.count
      assert_includes ticket.upvotes, upvote1
      assert_includes ticket.upvotes, upvote2
    end

    test "should count upvotes" do
      ticket = Ticket.create!(
        title: "Vote Counter",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_equal 0, ticket.upvotes_count

      ticket.upvotes.create!(user_id: 1)
      ticket.upvotes.create!(user_id: 2)

      assert_equal 2, ticket.upvotes_count
    end

    test "should check if upvoted by user" do
      ticket = Ticket.create!(
        title: "User Vote Check",
        description: "Description",
        user_id: 1,
        board: @board
      )

      # Mock user object
      user = Struct.new(:id).new(1)
      other_user = Struct.new(:id).new(2)

      assert_not ticket.upvoted_by?(user)

      ticket.upvotes.create!(user_id: user.id)

      assert ticket.upvoted_by?(user)
      assert_not ticket.upvoted_by?(other_user)
    end

    test "should not be locked by default" do
      ticket = Ticket.create!(
        title: "Unlocked Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_not ticket.locked?
      assert ticket.can_be_voted_on?
      assert ticket.can_be_commented_on?
    end

    test "should prevent voting and commenting when locked" do
      ticket = Ticket.create!(
        title: "Locked Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: true
      )

      assert ticket.locked?
      assert_not ticket.can_be_voted_on?
      assert_not ticket.can_be_commented_on?
    end

    test "should get status information" do
      ticket = Ticket.create!(
        title: "Status Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        status_slug: 'open'
      )

      assert_equal 'Open', ticket.status_name
      status = ticket.status
      assert status
      assert_equal 'Open', status.name
      assert_equal 'green', status.color
    end

    test "should filter by status" do
      open_ticket = Ticket.create!(
        title: "Open Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        status_slug: 'open'
      )

      closed_ticket = Ticket.create!(
        title: "Closed Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        status_slug: 'closed'
      )

      open_tickets = Ticket.by_status('open')
      closed_tickets = Ticket.by_status('closed')

      assert_includes open_tickets, open_ticket
      assert_not_includes open_tickets, closed_ticket

      assert_includes closed_tickets, closed_ticket
      assert_not_includes closed_tickets, open_ticket
    end

    test "should scope unlocked tickets" do
      unlocked = Ticket.create!(
        title: "Unlocked",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: false
      )

      locked = Ticket.create!(
        title: "Locked",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: true
      )

      unlocked_tickets = Ticket.unlocked

      assert_includes unlocked_tickets, unlocked
      assert_not_includes unlocked_tickets, locked
    end

    test "should order by recent" do
      old_ticket = Ticket.create!(
        title: "Old Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        created_at: 2.days.ago
      )

      new_ticket = Ticket.create!(
        title: "New Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        created_at: 1.hour.ago
      )

      recent_tickets = Ticket.recent

      assert_equal new_ticket, recent_tickets.first
      assert_equal old_ticket, recent_tickets.last
    end
  end
end
