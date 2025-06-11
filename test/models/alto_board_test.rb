require "test_helper"

module Alto
  class BoardTest < ActiveSupport::TestCase
    def setup
      # Use fixtures instead of manually creating status sets
      @status_set = alto_status_sets(:default)
    end

    test "should create board with valid attributes" do
      board = Board.new(
        name: "Test Board",
        description: "A test board",
        status_set: @status_set,
        item_label_singular: "ticket"
      )

      assert board.valid?
      assert board.save
      assert_equal "test-board", board.slug
    end

    test "should require name" do
      board = Board.new(description: "No name", status_set: @status_set, item_label_singular: "ticket")
      assert_not board.valid?
      assert_includes board.errors[:name], "can't be blank"
    end

    test "should auto-generate slug from name" do
      board = Board.create!(
        name: "My Awesome Board!",
        status_set: @status_set,
        item_label_singular: "ticket"
      )

      assert_equal "my-awesome-board", board.slug
    end

    test "should auto-increment slug for duplicate names" do
      first_board = Board.create!(name: "Unique Board", status_set: @status_set, item_label_singular: "ticket")
      assert_equal "unique-board", first_board.slug

      duplicate = Board.create!(name: "Unique Board", status_set: @status_set, item_label_singular: "ticket")
      assert_equal "unique-board-1", duplicate.slug
      assert duplicate.valid?
    end

    test "should have many tickets" do
      board = Board.create!(name: "Board with Tickets", status_set: @status_set, item_label_singular: "ticket")

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
      board = Board.create!(name: "Board with Status", status_set: @status_set, item_label_singular: "ticket")
      assert board.has_status_tracking?
    end

    test "should not have status tracking without status_set" do
      # Create a board with a status set but no statuses in it
      empty_status_set = ::Alto::StatusSet.create!(
        name: 'Empty Status Set',
        description: 'Status set with no statuses'
      )
      board = Board.create!(name: "Board without Status", status_set: empty_status_set, item_label_singular: "ticket")
      assert_not board.has_status_tracking?
    end

    test "should find available statuses" do
      board = Board.create!(name: "Status Board", status_set: @status_set, item_label_singular: "ticket")
      statuses = board.available_statuses

      assert_equal 3, statuses.count
      assert_equal ['open', 'in-progress', 'closed'], statuses.map(&:slug)
    end

    test "should find status by slug" do
      board = Board.create!(name: "Status Board", status_set: @status_set, item_label_singular: "ticket")
      status = board.status_by_slug('open')

      assert status
      assert_equal 'Open', status.name
      assert_equal 'green', status.color
    end

    test "should get default status slug" do
      board = Board.create!(name: "Status Board", status_set: @status_set, item_label_singular: "ticket")
      assert_equal 'open', board.default_status_slug
    end

    test "to_param should return slug" do
      board = Board.create!(name: "Test Board", status_set: @status_set, item_label_singular: "ticket")
      assert_equal board.slug, board.to_param
    end
  end
end
