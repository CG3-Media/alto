require "test_helper"

module Alto
  class BoardTaggingTest < ActiveSupport::TestCase
    def setup
      # Create status set first
      @status_set = StatusSet.create!(name: "Default", is_default: true)
      @status_set.statuses.create!(name: "Open", color: "green", position: 1, slug: "open")
      
      # Create board
      @board = Board.create!(
        name: "General Feedback",
        slug: "general-feedback",
        description: "General feedback and suggestions",
        status_set: @status_set,
        item_label_singular: "ticket"
      )
      
      # Create user
      @user = User.create!(email: "test@example.com")
    end

    test "should have many tags" do
      assert_respond_to @board, :tags
      assert_equal [], @board.tags.to_a
    end

    test "should allow creating tags" do
      tag = @board.tags.create!(name: "feature")
      
      assert tag.persisted?
      assert_equal @board, tag.board
      assert_includes @board.tags, tag
    end

    test "should have allow_public_tagging setting" do
      assert_respond_to @board, :allow_public_tagging
      assert_respond_to @board, :allow_public_tagging?
      
      # Should default to false
      assert_not @board.allow_public_tagging?
    end

    test "should allow setting allow_public_tagging" do
      @board.update!(allow_public_tagging: true)
      
      assert @board.allow_public_tagging?
    end

    test "should provide available_tags method" do
      tag1 = @board.tags.create!(name: "bug")
      tag2 = @board.tags.create!(name: "feature")
      
      available_tags = @board.available_tags
      
      assert_includes available_tags, tag1
      assert_includes available_tags, tag2
    end

    test "should provide available_tags ordered by name" do
      tag_c = @board.tags.create!(name: "charlie")
      tag_a = @board.tags.create!(name: "alpha")
      tag_b = @board.tags.create!(name: "bravo")
      
      available_tags = @board.available_tags
      
      assert_equal [tag_a, tag_b, tag_c], available_tags.to_a
    end

    test "should provide tags_for_select method" do
      tag1 = @board.tags.create!(name: "bug")
      tag2 = @board.tags.create!(name: "feature")
      
      options = @board.tags_for_select
      
      assert_includes options, ["bug", tag1.id]
      assert_includes options, ["feature", tag2.id]
    end

    test "should provide find_or_create_tag method" do
      # Test creating new tag
      tag = @board.find_or_create_tag("new-tag")
      
      assert tag.persisted?
      assert_equal "new-tag", tag.name
      assert_equal @board, tag.board
      
      # Test finding existing tag
      same_tag = @board.find_or_create_tag("new-tag")
      
      assert_equal tag, same_tag
    end

    test "should handle color-coded tags" do
      tag = @board.tags.create!(name: "urgent", color: "#ff0000")
      
      assert_equal "#ff0000", tag.color
      assert_includes @board.tags, tag
    end

    test "should provide most_used_tags method" do
      tag1 = @board.tags.create!(name: "common")
      tag2 = @board.tags.create!(name: "rare")
      tag3 = @board.tags.create!(name: "popular")
      
      # Simulate usage counts (this will work once we implement the counter cache)
      tag1.update!(usage_count: 5)
      tag2.update!(usage_count: 1)
      tag3.update!(usage_count: 10)
      
      most_used = @board.most_used_tags(2)
      
      assert_equal [tag3, tag1], most_used.to_a
    end

    test "should validate tags belong to board when tagging tickets" do
      other_board = Board.create!(
        name: "Bug Reports", 
        slug: "bug-reports",
        description: "Report bugs and issues",
        status_set: @status_set,
        item_label_singular: "bug"
      )
      other_board_tag = other_board.tags.create!(name: "other-tag")
      
      ticket = Ticket.create!(
        title: "Test Ticket",
        description: "Description",
        user_id: @user.id,
        board: @board
      )
      
      # This should fail when we implement the validation
      assert_raises(ActiveRecord::RecordInvalid) do
        ticket.tags << other_board_tag
      end
    end

    test "should scope tickets by tags within board" do
      tag1 = @board.tags.create!(name: "bug")
      tag2 = @board.tags.create!(name: "feature")
      
      ticket1 = Ticket.create!(
        title: "Bug Ticket",
        description: "A bug",
        user_id: @user.id,
        board: @board
      )
      ticket1.tags << tag1
      
      ticket2 = Ticket.create!(
        title: "Feature Ticket",
        description: "A feature",
        user_id: @user.id,
        board: @board
      )
      ticket2.tags << tag2
      
      bug_tickets = @board.tickets.tagged_with("bug")
      feature_tickets = @board.tickets.tagged_with("feature")
      
      assert_includes bug_tickets, ticket1
      assert_not_includes bug_tickets, ticket2
      
      assert_includes feature_tickets, ticket2
      assert_not_includes feature_tickets, ticket1
    end

    test "should delete tags when board is deleted" do
      tag = @board.tags.create!(name: "to-be-deleted")
      tag_id = tag.id
      
      @board.destroy!
      
      assert_not Tag.exists?(tag_id)
    end

    test "should not allow tag deletion if tags are in use and configured to prevent it" do
      # This test assumes we might have a configuration to prevent deletion of used tags
      tag = @board.tags.create!(name: "in-use")
      
      ticket = Ticket.create!(
        title: "Tagged Ticket",
        description: "Description", 
        user_id: @user.id,
        board: @board
      )
      ticket.tags << tag
      
      # For now, just verify the tag exists and is in use
      assert_equal 1, tag.usage_count
      assert tag.persisted?
    end
  end
end