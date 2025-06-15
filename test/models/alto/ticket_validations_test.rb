require "test_helper"

module Alto
  class TicketValidationsTest < ActiveSupport::TestCase
    def setup
      @user1 = users(:one)
      @user2 = users(:two)
      @status_set = alto_status_sets(:default)
      @board = alto_boards(:bugs)
    end

    test "should create ticket with valid attributes" do
      ticket = Ticket.new(
        title: "Test Ticket",
        description: "A test ticket description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Medium",
          "steps_to_reproduce" => "1. Open browser\n2. Navigate to page\n3. Observe issue"
        }
      )

      assert ticket.valid?
      assert ticket.save
      assert_equal "open", ticket.status_slug
    end

    test "should require title" do
      ticket = Ticket.new(
        description: "No title",
        user_id: @user1.id,
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:title], "can't be blank"
    end

    test "should require description" do
      ticket = Ticket.new(
        title: "Title Only",
        user_id: @user1.id,
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
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Low",
          "steps_to_reproduce" => "Basic reproduction steps"
        }
      )

      assert_equal @board, ticket.board
    end

    test "should have many comments" do
      ticket = Ticket.create!(
        title: "Ticket with Comments",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "High",
          "steps_to_reproduce" => "Steps for commenting test"
        }
      )

      comment1 = ticket.comments.create!(content: "First comment", user_id: @user1.id)
      comment2 = ticket.comments.create!(content: "Second comment", user_id: @user2.id)

      assert_equal 2, ticket.comments.count
      assert_includes ticket.comments, comment1
      assert_includes ticket.comments, comment2
    end

    test "should have many upvotes" do
      ticket = Ticket.create!(
        title: "Upvoted Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Critical",
          "steps_to_reproduce" => "Steps for upvoting test"
        }
      )

      upvote1 = ticket.upvotes.create!(user_id: @user1.id)
      upvote2 = ticket.upvotes.create!(user_id: @user2.id)

      assert_equal 2, ticket.upvotes.count
      assert_includes ticket.upvotes, upvote1
      assert_includes ticket.upvotes, upvote2
    end

    test "should count upvotes" do
      ticket = Ticket.create!(
        title: "Vote Counter",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Medium",
          "steps_to_reproduce" => "Steps for vote counting"
        }
      )

      assert_equal 0, ticket.upvotes_count

      ticket.upvotes.create!(user_id: @user1.id)
      ticket.upvotes.create!(user_id: @user2.id)

      assert_equal 2, ticket.upvotes_count
    end

    test "should check if upvoted by user" do
      ticket = Ticket.create!(
        title: "User Vote Check",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Low",
          "steps_to_reproduce" => "Steps for user vote check"
        }
      )

      # Use fixture users instead of mocks
      user = @user1
      other_user = @user2

      assert_not ticket.upvoted_by?(user)

      ticket.upvotes.create!(user_id: user.id)

      assert ticket.upvoted_by?(user)
      assert_not ticket.upvoted_by?(other_user)
    end

    test "should not be locked by default" do
      ticket = Ticket.create!(
        title: "Unlocked Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Medium",
          "steps_to_reproduce" => "Steps for lock test"
        }
      )

      assert_not ticket.locked?
      assert ticket.can_be_voted_on?
      assert ticket.can_be_commented_on?
    end

    test "should prevent voting and commenting when locked" do
      ticket = Ticket.create!(
        title: "Locked Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        locked: true,
        field_values: {
          "severity" => "High",
          "steps_to_reproduce" => "Steps for locked ticket test"
        }
      )

      assert ticket.locked?
      assert_not ticket.can_be_voted_on?
      assert_not ticket.can_be_commented_on?
    end
  end
end
