require "test_helper"

module Alto
  class UpvoteTest < ActiveSupport::TestCase
    def setup
      # Use fixtures instead of manual creation
      @user1 = users(:one)
      @user2 = users(:two)

      # Use existing fixture board and create test data properly
      @board = alto_boards(:bugs)
      @ticket = @board.tickets.create!(
        title: "Test Ticket",
        description: "Description",
        user: @user1,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test steps"
        }
      )
      @comment = @ticket.comments.create!(
        content: "Test Comment",
        user: @user2
      )
    end

    test "should create upvote for ticket" do
      upvote = Upvote.new(
        upvotable: @ticket,
        user_id: @user1.id
      )

      assert upvote.valid?
      assert upvote.save
      assert_equal @ticket, upvote.upvotable
      assert_equal "Alto::Ticket", upvote.upvotable_type
    end

    test "should create upvote for comment" do
      upvote = Upvote.new(
        upvotable: @comment,
        user_id: @user1.id
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
      Upvote.create!(upvotable: @ticket, user_id: @user1.id)

      # Try to create duplicate
      duplicate = Upvote.new(upvotable: @ticket, user_id: @user1.id)

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:user_id], "has already been taken"
    end

    test "should allow different users to upvote same item" do
      upvote1 = Upvote.create!(upvotable: @ticket, user_id: @user1.id)
      upvote2 = Upvote.create!(upvotable: @ticket, user_id: @user2.id)

      assert upvote1.valid?
      assert upvote2.valid?
      assert_equal 2, @ticket.upvotes.count
    end

    test "should allow same user to upvote different items" do
      ticket_upvote = Upvote.create!(upvotable: @ticket, user_id: @user1.id)
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: @user1.id)

      assert ticket_upvote.valid?
      assert comment_upvote.valid?
    end

    test "should scope upvotes for tickets" do
      ticket_upvote = Upvote.create!(upvotable: @ticket, user_id: @user1.id)
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: @user2.id)

      ticket_upvotes = Upvote.for_tickets

      assert_includes ticket_upvotes, ticket_upvote
      assert_not_includes ticket_upvotes, comment_upvote
    end

    test "should scope upvotes for comments" do
      ticket_upvote = Upvote.create!(upvotable: @ticket, user_id: @user1.id)
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: @user2.id)

      comment_upvotes = Upvote.for_comments

      assert_includes comment_upvotes, comment_upvote
      assert_not_includes comment_upvotes, ticket_upvote
    end

    test "should work with polymorphic queries" do
      # Create upvotes for different types
      Upvote.create!(upvotable: @ticket, user_id: @user1.id)
      Upvote.create!(upvotable: @comment, user_id: @user1.id)

      # Query by upvotable
      ticket_upvotes = Upvote.where(upvotable: @ticket)
      comment_upvotes = Upvote.where(upvotable: @comment)

      assert_equal 1, ticket_upvotes.count
      assert_equal 1, comment_upvotes.count

      assert_equal @ticket, ticket_upvotes.first.upvotable
      assert_equal @comment, comment_upvotes.first.upvotable
    end

    test "should maintain referential integrity" do
      upvote = Upvote.create!(upvotable: @ticket, user_id: @user1.id)

      # Delete the ticket
      @ticket.destroy

      # Upvote should also be deleted (dependent: :destroy)
      assert_not Upvote.exists?(upvote.id)
    end

    test "should handle destruction of upvotable" do
      comment_upvote = Upvote.create!(upvotable: @comment, user_id: @user1.id)

      # Delete the comment
      @comment.destroy

      # Upvote should also be deleted
      assert_not Upvote.exists?(comment_upvote.id)
    end
  end
end
