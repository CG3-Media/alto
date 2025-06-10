require "test_helper"

module Alto
  class BoardTest < ActiveSupport::TestCase
    def setup
      # Create a test status set
      @status_set = ::Alto::StatusSet.create!(
        name: 'Test Status Set',
        description: 'For testing',
        is_default: true
      )

      # Create some statuses
      @status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')
      @status_set.statuses.create!(name: 'Closed', color: 'gray', position: 1, slug: 'closed')
    end

    test "should create board with valid attributes" do
      board = Board.new(
        name: "Test Board",
        description: "A test board",
        status_set: @status_set
      )

      assert board.valid?
      assert board.save
      assert_equal "test-board", board.slug
    end

    test "should require name" do
      board = Board.new(description: "No name")
      assert_not board.valid?
      assert_includes board.errors[:name], "can't be blank"
    end

    test "should auto-generate slug from name" do
      board = Board.create!(
        name: "My Awesome Board!",
        status_set: @status_set
      )

      assert_equal "my-awesome-board", board.slug
    end

    test "should auto-increment slug for duplicate names" do
      first_board = Board.create!(name: "Unique Board", status_set: @status_set)
      assert_equal "unique-board", first_board.slug

      duplicate = Board.create!(name: "Unique Board", status_set: @status_set)
      assert_equal "unique-board-1", duplicate.slug
      assert duplicate.valid?
    end

    test "should have many tickets" do
      board = Board.create!(name: "Board with Tickets", status_set: @status_set)

      ticket1 = board.tickets.create!(
        title: "First Ticket",
        description: "Description",
        user_id: 1,
        status_slug: 'open'
      )

      ticket2 = board.tickets.create!(
        title: "Second Ticket",
        description: "Description",
        user_id: 1,
        status_slug: 'open'
      )

      assert_equal 2, board.tickets.count
      assert_includes board.tickets, ticket1
      assert_includes board.tickets, ticket2
    end

    test "should have status tracking when status_set present" do
      board = Board.create!(name: "Board with Status", status_set: @status_set)
      assert board.has_status_tracking?
    end

    test "should not have status tracking without status_set" do
      board = Board.create!(name: "Board without Status", status_set: nil)
      assert_not board.has_status_tracking?
    end

    test "should find available statuses" do
      board = Board.create!(name: "Status Board", status_set: @status_set)
      statuses = board.available_statuses

      assert_equal 2, statuses.count
      assert_equal ['open', 'closed'], statuses.map(&:slug)
    end

    test "should find status by slug" do
      board = Board.create!(name: "Status Board", status_set: @status_set)
      status = board.status_by_slug('open')

      assert status
      assert_equal 'Open', status.name
      assert_equal 'green', status.color
    end

    test "should get default status slug" do
      board = Board.create!(name: "Status Board", status_set: @status_set)
      assert_equal 'open', board.default_status_slug
    end

    test "to_param should return slug" do
      board = Board.create!(name: "Test Board", status_set: @status_set)
      assert_equal board.slug, board.to_param
    end
  end
end
