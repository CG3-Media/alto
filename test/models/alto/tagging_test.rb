require "test_helper"

module Alto
  class TaggingTest < ActiveSupport::TestCase
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
      
      @tag = Tag.create!(name: "test-tag", board: @board)
      @ticket = Ticket.create!(
        title: "Test Ticket",
        description: "A test ticket for tagging",
        user_id: @user.id,
        board: @board
      )
    end

    test "should create tagging with valid attributes" do
      tagging = Tagging.new(
        tag: @tag,
        taggable: @ticket
      )

      assert tagging.valid?
      assert tagging.save
    end

    test "should require tag" do
      tagging = Tagging.new(taggable: @ticket)

      assert_not tagging.valid?
      assert_includes tagging.errors[:tag], "must exist"
    end

    test "should require taggable" do
      tagging = Tagging.new(tag: @tag)

      assert_not tagging.valid?
      assert_includes tagging.errors[:taggable], "must exist"
    end

    test "should belong to tag" do
      tagging = Tagging.create!(tag: @tag, taggable: @ticket)

      assert_equal @tag, tagging.tag
    end

    test "should belong to taggable polymorphically" do
      tagging = Tagging.create!(tag: @tag, taggable: @ticket)

      assert_equal @ticket, tagging.taggable
      assert_equal "Alto::Ticket", tagging.taggable_type
      assert_equal @ticket.id, tagging.taggable_id
    end

    test "should validate tag and taggable belong to same board" do
      other_board = Board.create!(
        name: "Bug Reports", 
        slug: "bug-reports",
        description: "Report bugs and issues",
        status_set: @status_set,
        item_label_singular: "bug"
      )
      other_board_tag = Tag.create!(name: "other-tag", board: other_board)
      
      tagging = Tagging.new(tag: other_board_tag, taggable: @ticket)
      
      assert_not tagging.valid?
      assert_includes tagging.errors[:tag], "must belong to the same board as the tagged item"
    end

    test "should validate uniqueness of tag and taggable combination" do
      Tagging.create!(tag: @tag, taggable: @ticket)
      
      duplicate_tagging = Tagging.new(tag: @tag, taggable: @ticket)
      assert_not duplicate_tagging.valid?
      assert_includes duplicate_tagging.errors[:tag_id], "has already been taken"
    end

    test "should allow same tag on different taggables" do
      other_ticket = Ticket.create!(
        title: "Other Ticket",
        description: "Another test ticket",
        user_id: @user.id,
        board: @board
      )

      tagging1 = Tagging.create!(tag: @tag, taggable: @ticket)
      tagging2 = Tagging.new(tag: @tag, taggable: other_ticket)

      assert tagging2.valid?
      assert tagging2.save
      assert_not_equal tagging1.taggable, tagging2.taggable
    end

    test "should allow different tags on same taggable" do
      other_tag = Tag.create!(name: "other-tag", board: @board)

      tagging1 = Tagging.create!(tag: @tag, taggable: @ticket)
      tagging2 = Tagging.new(tag: other_tag, taggable: @ticket)

      assert tagging2.valid?
      assert tagging2.save
      assert_not_equal tagging1.tag, tagging2.tag
    end

    test "should update tag usage_count when created" do
      initial_count = @tag.usage_count
      
      Tagging.create!(tag: @tag, taggable: @ticket)
      @tag.reload
      
      assert_equal initial_count + 1, @tag.usage_count
    end

    test "should update tag usage_count when destroyed" do
      tagging = Tagging.create!(tag: @tag, taggable: @ticket)
      @tag.reload
      initial_count = @tag.usage_count
      
      tagging.destroy!
      @tag.reload
      
      assert_equal initial_count - 1, @tag.usage_count
    end

    test "should scope by tag" do
      other_tag = Tag.create!(name: "other-tag", board: @board)
      other_ticket = Ticket.create!(
        title: "Other Ticket",
        description: "Another ticket",
        user_id: @user.id,
        board: @board
      )

      tagging1 = Tagging.create!(tag: @tag, taggable: @ticket)
      tagging2 = Tagging.create!(tag: other_tag, taggable: other_ticket)

      tag_taggings = Tagging.for_tag(@tag)
      other_tag_taggings = Tagging.for_tag(other_tag)

      assert_includes tag_taggings, tagging1
      assert_not_includes tag_taggings, tagging2

      assert_includes other_tag_taggings, tagging2
      assert_not_includes other_tag_taggings, tagging1
    end

    test "should scope by taggable type" do
      # For now we only have tickets, but the system should support other types
      ticket_taggings = Tagging.for_taggable_type("Alto::Ticket")
      
      tagging = Tagging.create!(tag: @tag, taggable: @ticket)
      
      assert_includes ticket_taggings, tagging
    end

    test "should have board method that returns tag board" do
      tagging = Tagging.create!(tag: @tag, taggable: @ticket)
      
      assert_respond_to tagging, :board
      assert_equal @board, tagging.board
    end

    test "should work with different polymorphic types" do
      # Test that the polymorphic association works correctly
      tagging = Tagging.create!(tag: @tag, taggable: @ticket)
      
      # The taggable should be loaded correctly
      loaded_taggable = tagging.taggable
      assert_equal @ticket, loaded_taggable
      assert_instance_of Alto::Ticket, loaded_taggable
    end
  end
end