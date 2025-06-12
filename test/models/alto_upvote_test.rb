require "test_helper"

module Alto
  class UpvoteTest < ActiveSupport::TestCase
    def setup
      # Create test data
      @status_set = ::Alto::StatusSet.create!(
        name: "Test Status Set",
        is_default: true
      )
      @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")

      @board = Board.create!(name: "Test Board", status_set: @status_set)
      @ticket = @board.tickets.create!(
        title: "Test Ticket",
        description: "Description",
        user_id: 1
      )
      @comment = @ticket.comments.create!(
        content: "Test Comment",
        user_id: 2
      )
    end

    test "should create upvote for ticket" do
      upvote = Upvote.new(
        upvotable: @ticket,
        user_id: 1
      )

      assert upvote.valid?
      assert upvote.save
      assert_equal @ticket, upvote.upvotable
      assert_equal "Alto::Ticket", upvote.upvotable_type
    end

    test "should create upvote for comment" do
      upvote = Upvote.new(
        upvotable: @comment,
        user_id: 1
      )

      assert upvote.valid?
      assert upvote.save
      assert_equal @comment, upvote.upvotable
      assert_equal "Alto::Comment", upvote.upvotable_type
    end

    test "should require user_id" do
      upvote = Upvote.new(upvotable: @ticket)

      assert_not upvote.valid?
      assert_includes upvote.errors[:user_id], "can't be blank"
    end

    test "should enforce uniqueness per user and upvotable" do
      # Create first upvote
      Upvote.create!(upvotable: @ticket, user_id: 1)

      # Try to create duplicate
      duplicate = Upvote.new(upvotable: @ticket, user_id: 1)

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:user_id], "has already been taken"
    end

    test "should allow different users to upvote same item" do
      upvote1 = Upvote.create!(upvotable: @ticket, user_id: 1)
      upvote2 = Upvote.create!(upvotable: @ticket, user_id: 2)

      assert upvote1.valid?
      assert upvote2.valid?
      assert_equal 2, @ticket.upvotes.count
    end

    test "should allow same user to upvote different items" do
      ticket_upvote = Upvote.create!(upvotable: @ticket, user_id: 1)
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: 1)

      assert ticket_upvote.valid?
      assert comment_upvote.valid?
    end

    test "should scope upvotes for tickets" do
      ticket_upvote = Upvote.create!(upvotable: @ticket, user_id: 1)
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: 2)

      ticket_upvotes = Upvote.for_tickets

      assert_includes ticket_upvotes, ticket_upvote
      assert_not_includes ticket_upvotes, comment_upvote
    end

    test "should scope upvotes for comments" do
      ticket_upvote = Upvote.create!(upvotable: @ticket, user_id: 1)
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: 2)

      comment_upvotes = Upvote.for_comments

      assert_includes comment_upvotes, comment_upvote
      assert_not_includes comment_upvotes, ticket_upvote
    end

    test "should work with polymorphic queries" do
      # Create upvotes for different types
      Upvote.create!(upvotable: @ticket, user_id: 1)
      Upvote.create!(upvotable: @comment, user_id: 1)

      # Query by upvotable
      ticket_upvotes = Upvote.where(upvotable: @ticket)
      comment_upvotes = Upvote.where(upvotable: @comment)

      assert_equal 1, ticket_upvotes.count
      assert_equal 1, comment_upvotes.count

      assert_equal @ticket, ticket_upvotes.first.upvotable
      assert_equal @comment, comment_upvotes.first.upvotable
    end

    test "should maintain referential integrity" do
      upvote = Upvote.create!(upvotable: @ticket, user_id: 1)

      # Delete the ticket
      @ticket.destroy

      # Upvote should also be deleted (dependent: :destroy)
      assert_not Upvote.exists?(upvote.id)
    end

    test "should handle destruction of upvotable" do
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: 1)

      # Delete the comment
      @comment.destroy

      # Upvote should also be deleted
      assert_not Upvote.exists?(comment_upvote.id)
    end
  end
end
