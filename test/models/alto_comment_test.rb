require "test_helper"

module Alto
  class CommentTest < ActiveSupport::TestCase
    def setup
      # Create test users to ensure they exist for validation
      @user1 = User.find_or_create_by!(id: 1) { |u| u.email = 'test1@example.com' }
      @user2 = User.find_or_create_by!(id: 2) { |u| u.email = 'test2@example.com' }
      @user3 = User.find_or_create_by!(id: 3) { |u| u.email = 'test3@example.com' }
      @user4 = User.find_or_create_by!(id: 4) { |u| u.email = 'test4@example.com' }

      # Create test board and ticket
      @status_set = ::Alto::StatusSet.create!(
        name: 'Test Status Set',
        is_default: true
      )
      @status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')

      @board = Board.create!(name: "Test Board", status_set: @status_set)
      @ticket = @board.tickets.create!(
        title: "Test Ticket",
        description: "Description",
        user_id: 1
      )
    end

    test "should create comment with valid attributes" do
      comment = Comment.new(
        content: "This is a test comment",
        user_id: 1,
        ticket: @ticket
      )

      assert comment.valid?
      assert comment.save
      assert_equal 0, comment.depth  # Top-level comment
    end

    test "should require content" do
      comment = Comment.new(
        user_id: 1,
        ticket: @ticket
      )

      assert_not comment.valid?
      assert_includes comment.errors[:content], "can't be blank"
    end

    test "should require user_id" do
      comment = Comment.new(
        content: "No user",
        ticket: @ticket
      )

      assert_not comment.valid?
      assert_includes comment.errors[:user_id], "can't be blank"
    end

    test "should belong to ticket" do
      comment = Comment.create!(
        content: "Ticket comment",
        user_id: 1,
        ticket: @ticket
      )

      assert_equal @ticket, comment.ticket
    end

    test "should have many upvotes" do
      comment = Comment.create!(
        content: "Upvoted comment",
        user_id: 1,
        ticket: @ticket
      )

      upvote1 = comment.upvotes.create!(user_id: 1)
      upvote2 = comment.upvotes.create!(user_id: 2)

      assert_equal 2, comment.upvotes.count
      assert_includes comment.upvotes, upvote1
      assert_includes comment.upvotes, upvote2
    end

    test "should count upvotes" do
      comment = Comment.create!(
        content: "Vote counter",
        user_id: 1,
        ticket: @ticket
      )

      assert_equal 0, comment.upvotes_count

      comment.upvotes.create!(user_id: 1)
      comment.upvotes.create!(user_id: 2)

      assert_equal 2, comment.upvotes_count
    end

    test "should check if upvoted by user" do
      comment = Comment.create!(
        content: "User vote check",
        user_id: 1,
        ticket: @ticket
      )

      user = Struct.new(:id).new(1)
      other_user = Struct.new(:id).new(2)

      assert_not comment.upvoted_by?(user)

      comment.upvotes.create!(user_id: user.id)

      assert comment.upvoted_by?(user)
      assert_not comment.upvoted_by?(other_user)
    end

    test "should allow voting when ticket unlocked" do
      comment = Comment.create!(
        content: "Votable comment",
        user_id: 1,
        ticket: @ticket
      )

      assert comment.can_be_voted_on?
    end

    test "should prevent voting when ticket locked" do
      @ticket.update!(locked: true)

      comment = Comment.create!(
        content: "Non-votable comment",
        user_id: 1,
        ticket: @ticket
      )

      assert_not comment.can_be_voted_on?
    end

    test "should create reply to comment" do
      parent_comment = Comment.create!(
        content: "Parent comment",
        user_id: 1,
        ticket: @ticket
      )

      reply = Comment.create!(
        content: "Reply to parent",
        user_id: 2,
        ticket: @ticket,
        parent: parent_comment
      )

      assert_equal parent_comment, reply.parent
      assert_equal 1, reply.depth
      assert reply.is_reply?
      assert_includes parent_comment.replies, reply
    end

    test "should create nested reply" do
      parent = Comment.create!(
        content: "Parent comment",
        user_id: 1,
        ticket: @ticket
      )

      reply = Comment.create!(
        content: "First reply",
        user_id: 2,
        ticket: @ticket,
        parent: parent
      )

      nested_reply = Comment.create!(
        content: "Nested reply",
        user_id: 3,
        ticket: @ticket,
        parent: reply
      )

      assert_equal 0, parent.depth
      assert_equal 1, reply.depth
      assert_equal 2, nested_reply.depth
      assert_equal parent, nested_reply.thread_root
    end

    test "should limit depth to 3 levels" do
      parent = Comment.create!(
        content: "Parent",
        user_id: 1,
        ticket: @ticket
      )

      reply = Comment.create!(
        content: "Reply",
        user_id: 2,
        ticket: @ticket,
        parent: parent
      )

      nested_reply = Comment.create!(
        content: "Nested reply",
        user_id: 3,
        ticket: @ticket,
        parent: reply
      )

      # Try to create 4th level - should fail
      deep_reply = Comment.new(
        content: "Too deep",
        user_id: 4,
        ticket: @ticket,
        parent: nested_reply
      )

      assert_not deep_reply.valid?
      assert_includes deep_reply.errors[:depth], "must be less than 3"
    end

    test "should check if can be replied to" do
      parent = Comment.create!(
        content: "Parent",
        user_id: 1,
        ticket: @ticket
      )

      reply = Comment.create!(
        content: "Reply",
        user_id: 2,
        ticket: @ticket,
        parent: parent
      )

      nested_reply = Comment.create!(
        content: "Nested reply",
        user_id: 3,
        ticket: @ticket,
        parent: reply
      )

      assert parent.can_be_replied_to?    # depth 0
      assert reply.can_be_replied_to?     # depth 1
      assert_not nested_reply.can_be_replied_to?  # depth 2 (max)
    end

    test "should not allow replies when ticket locked" do
      comment = Comment.create!(
        content: "Comment",
        user_id: 1,
        ticket: @ticket
      )

      @ticket.update!(locked: true)

      assert_not comment.can_be_replied_to?
    end

    test "should validate parent from same ticket" do
      other_ticket = @board.tickets.create!(
        title: "Other Ticket",
        description: "Description",
        user_id: 1
      )

      parent = Comment.create!(
        content: "Parent on other ticket",
        user_id: 1,
        ticket: other_ticket
      )

      invalid_reply = Comment.new(
        content: "Invalid reply",
        user_id: 2,
        ticket: @ticket,  # Different ticket!
        parent: parent
      )

      assert_not invalid_reply.valid?
      assert_includes invalid_reply.errors[:parent], "must be from the same ticket"
    end

    test "should build threaded structure" do
      # Create comment hierarchy
      comment1 = Comment.create!(content: "First comment", user_id: 1, ticket: @ticket)
      reply1 = Comment.create!(content: "Reply to first", user_id: 2, ticket: @ticket, parent: comment1)
      nested1 = Comment.create!(content: "Nested reply", user_id: 3, ticket: @ticket, parent: reply1)

      comment2 = Comment.create!(content: "Second comment", user_id: 4, ticket: @ticket)

      threaded = Comment.threaded_for_ticket(@ticket)

      assert_equal 2, threaded.length  # Two top-level comments

      # First thread
      first_thread = threaded.first
      assert_equal comment1, first_thread[:comment]
      assert_equal 1, first_thread[:replies].length

      # Check nested structure
      reply_thread = first_thread[:replies].first
      assert_equal reply1, reply_thread[:comment]
      assert_equal 1, reply_thread[:replies].length
      assert_equal nested1, reply_thread[:replies].first[:comment]

      # Second thread
      second_thread = threaded.last
      assert_equal comment2, second_thread[:comment]
      assert_equal 0, second_thread[:replies].length
    end

    test "should scope top level comments" do
      top_level = Comment.create!(content: "Top level", user_id: 1, ticket: @ticket)
      reply = Comment.create!(content: "Reply", user_id: 2, ticket: @ticket, parent: top_level)

      top_comments = Comment.top_level

      assert_includes top_comments, top_level
      assert_not_includes top_comments, reply
    end

    test "should order by creation time" do
      old_comment = Comment.create!(
        content: "Old comment",
        user_id: 1,
        ticket: @ticket,
        created_at: 2.hours.ago
      )

      new_comment = Comment.create!(
        content: "New comment",
        user_id: 2,
        ticket: @ticket,
        created_at: 1.hour.ago
      )

      recent_comments = Comment.recent

      assert_equal new_comment, recent_comments.first
      assert_equal old_comment, recent_comments.last
    end
  end
end
