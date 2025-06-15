require "test_helper"

module Alto
  class WorkflowScenariosTest < ActiveSupport::TestCase
    # Rule 2: Prefer fixtures over factories
    def setup
      @status_set = StatusSet.create!(name: "Default", is_default: true)
      @open_status = @status_set.statuses.create!(name: "Open", color: "green", position: 1, slug: "open")
      @closed_status = @status_set.statuses.create!(name: "Closed", color: "red", position: 2, slug: "closed")

      @board = Board.create!(
        name: "Feature Requests",
        slug: "feature-requests",
        description: "Board for feature requests",
        status_set: @status_set,
        item_label_singular: "feature"
      )

      @user1 = User.create!(email: "user1@example.com")
      @user2 = User.create!(email: "user2@example.com")
    end

    # Test ticket lifecycle scenarios
    test "complete ticket creation workflow" do
      # Rule 7: Assert DB side-effects
      assert_difference "Ticket.count", 1 do
        ticket = Ticket.create!(
          title: "Add dark mode",
          description: "Users want dark mode support",
          user_id: @user1.id,
          board: @board
        )

        assert ticket.persisted?
        assert_equal "open", ticket.status_slug
      end
    end

    test "ticket commenting workflow" do
      ticket = Ticket.create!(
        title: "API Documentation",
        description: "Need better API docs",
        user_id: @user1.id,
        board: @board
      )

      # Rule 7: Assert DB side-effects
      assert_difference "Comment.count", 2 do
        # User 1 comments
        comment1 = ticket.comments.create!(
          content: "This is a great idea",
          user_id: @user1.id
        )

        # User 2 replies
        comment2 = ticket.comments.create!(
          content: "I agree, very needed",
          user_id: @user2.id,
          parent: comment1
        )

        assert_equal comment1, comment2.parent
        assert_equal 0, comment1.depth
        assert_equal 1, comment2.depth
      end
    end

    test "ticket upvoting workflow" do
      ticket = Ticket.create!(
        title: "Mobile App",
        description: "Build a mobile app",
        user_id: @user1.id,
        board: @board
      )

      # Rule 7: Assert DB side-effects
      assert_difference "Upvote.count", 2 do
        # Different users upvote
        upvote1 = ticket.upvotes.create!(user_id: @user1.id)
        upvote2 = ticket.upvotes.create!(user_id: @user2.id)

        assert upvote1.persisted?
        assert upvote2.persisted?
      end

      assert_equal 2, ticket.upvotes_count
    end

            test "board with custom fields setup" do
      # Create custom fields for the board
      priority_field = @board.fields.create!(
        label: "Priority",
        field_type: "text_field",
        required: false,
        position: 1
      )

      description_field = @board.fields.create!(
        label: "Additional Details",
        field_type: "text_field",
        required: false,
        position: 2
      )

      # Verify fields were created
      assert priority_field.persisted?
      assert description_field.persisted?
      assert_equal @board, priority_field.board
      assert_equal @board, description_field.board

      # Create a basic ticket on this board
      ticket = Ticket.create!(
        title: "New Feature Request",
        description: "Description here",
        user_id: @user1.id,
        board: @board
      )

      # Verify ticket was created
      assert ticket.persisted?
      assert_equal @board, ticket.board
    end

    test "ticket tagging workflow" do
      # Create some tags
      bug_tag = @board.tags.create!(name: "bug", color: "#ff0000")
      feature_tag = @board.tags.create!(name: "feature", color: "#00ff00")

      ticket = Ticket.create!(
        title: "Fix login issue",
        description: "Login form is broken",
        user_id: @user1.id,
        board: @board
      )

      # Rule 7: Assert DB side-effects
      assert_difference "Tagging.count", 2 do
        # Tag the ticket
        ticket.tags << bug_tag
        ticket.tags << feature_tag
      end

      assert_includes ticket.tags, bug_tag
      assert_includes ticket.tags, feature_tag

      # Verify usage counts
      bug_tag.reload
      feature_tag.reload
      assert_equal 1, bug_tag.usage_count
      assert_equal 1, feature_tag.usage_count
    end

    test "ticket status change workflow" do
      ticket = Ticket.create!(
        title: "Status Test",
        description: "Testing status changes",
        user_id: @user1.id,
        board: @board
      )

      # Should start as open
      assert_equal "open", ticket.status_slug

      # Change to closed
      ticket.update!(status_slug: "closed")
      assert_equal "closed", ticket.status_slug
    end

    test "board with multiple tickets workflow" do
      # Create multiple tickets
      tickets = []

      # Rule 7: Assert DB side-effects
      assert_difference "Ticket.count", 3 do
        tickets << Ticket.create!(
          title: "First Feature",
          description: "First description",
          user_id: @user1.id,
          board: @board
        )

        tickets << Ticket.create!(
          title: "Second Feature",
          description: "Second description",
          user_id: @user2.id,
          board: @board
        )

        tickets << Ticket.create!(
          title: "Third Feature",
          description: "Third description",
          user_id: @user1.id,
          board: @board
        )
      end

      # Verify board has all tickets
      assert_equal 3, @board.tickets.count

      # Test scoping
      user1_tickets = @board.tickets.where(user_id: @user1.id)
      assert_equal 2, user1_tickets.count
    end

    test "subscription workflow" do
      ticket = Ticket.create!(
        title: "Subscription Test",
        description: "Testing subscriptions",
        user_id: @user1.id,
        board: @board
      )

      # Rule 7: Assert DB side-effects
      assert_difference "Subscription.count", 1 do
        subscription = ticket.subscriptions.create!(email: "test@example.com")
        assert subscription.persisted?
      end

      # Test uniqueness
      duplicate_subscription = ticket.subscriptions.new(email: "test@example.com")
      assert_not duplicate_subscription.valid?
    end

    test "archived ticket workflow" do
      ticket = Ticket.create!(
        title: "Archive Test",
        description: "Testing archive functionality",
        user_id: @user1.id,
        board: @board
      )

      # Should not be archived by default
      assert_not ticket.archived?

      # Archive the ticket
      ticket.update!(archived: true)
      assert ticket.archived?
      assert ticket.locked?

      # Archived tickets should be excluded from normal queries
      assert_not_includes @board.tickets.active, ticket
      assert_includes @board.tickets.archived, ticket
    end

    test "complex commenting thread workflow" do
      ticket = Ticket.create!(
        title: "Complex Comments",
        description: "Testing complex comment threads",
        user_id: @user1.id,
        board: @board
      )

      # Create nested comment structure
      comment1 = ticket.comments.create!(content: "Root comment", user_id: @user1.id)
      comment2 = ticket.comments.create!(content: "Reply 1", user_id: @user2.id, parent: comment1)
      comment3 = ticket.comments.create!(content: "Reply 2", user_id: @user1.id, parent: comment1)
      comment4 = ticket.comments.create!(content: "Nested reply", user_id: @user2.id, parent: comment2)

      # Verify structure
      assert_equal 2, comment1.replies.count
      assert_equal 1, comment2.replies.count
      assert_equal 0, comment3.replies.count

      # Test depths
      assert_equal 0, comment1.depth
      assert_equal 1, comment2.depth
      assert_equal 1, comment3.depth
      assert_equal 2, comment4.depth
    end

    test "multi-board isolation workflow" do
      # Create another board
      other_board = Board.create!(
        name: "Bug Reports",
        slug: "bug-reports",
        description: "Bug tracking board",
        status_set: @status_set,
        item_label_singular: "bug"
      )

      # Create tickets on different boards
      feature_ticket = Ticket.create!(
        title: "Feature Request",
        description: "A feature",
        user_id: @user1.id,
        board: @board
      )

      bug_ticket = Ticket.create!(
        title: "Bug Report",
        description: "A bug",
        user_id: @user1.id,
        board: other_board
      )

      # Verify isolation
      assert_includes @board.tickets, feature_ticket
      assert_not_includes @board.tickets, bug_ticket

      assert_includes other_board.tickets, bug_ticket
      assert_not_includes other_board.tickets, feature_ticket
    end

    test "upvote and comment integration workflow" do
      ticket = Ticket.create!(
        title: "Integration Test",
        description: "Testing upvotes and comments together",
        user_id: @user1.id,
        board: @board
      )

      comment = ticket.comments.create!(
        content: "Great idea!",
        user_id: @user2.id
      )

      # Upvote both ticket and comment
      ticket_upvote = ticket.upvotes.create!(user_id: @user1.id)
      comment_upvote = comment.upvotes.create!(user_id: @user1.id)

      assert ticket_upvote.persisted?
      assert comment_upvote.persisted?

      # Verify counts
      assert_equal 1, ticket.upvotes_count
      assert_equal 1, comment.upvotes_count
    end
  end
end
