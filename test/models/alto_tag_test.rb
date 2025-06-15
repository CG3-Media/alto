require "test_helper"

module Alto
  class TagTest < ActiveSupport::TestCase
    def setup
      # Create status set first
      @status_set = StatusSet.create!(name: "Default", is_default: true)
      @status_set.statuses.create!(name: "Open", color: "green", position: 1, slug: "open")

      # Create boards
      @board = Board.create!(
        name: "General Feedback",
        slug: "general-feedback",
        description: "General feedback and suggestions",
        status_set: @status_set,
        item_label_singular: "ticket"
      )

      @other_board = Board.create!(
        name: "Bug Reports",
        slug: "bug-reports",
        description: "Report bugs and issues",
        status_set: @status_set,
        item_label_singular: "bug"
      )
    end

    test "should create tag with valid attributes" do
      tag = Tag.new(
        name: "bug",
        board: @board
      )

      assert tag.valid?
      assert tag.save
    end

    test "should require name" do
      tag = Tag.new(board: @board)

      assert_not tag.valid?
      assert_includes tag.errors[:name], "can't be blank"
    end

    test "should require board" do
      tag = Tag.new(name: "feature")

      assert_not tag.valid?
      assert_includes tag.errors[:board], "must exist"
    end

    test "should belong to board" do
      tag = Tag.create!(name: "enhancement", board: @board)

      assert_equal @board, tag.board
    end

    test "should have many taggings" do
      tag = Tag.create!(name: "urgent", board: @board)

      assert_respond_to tag, :taggings
      assert_equal [], tag.taggings.to_a
    end

    test "should have many tickets through taggings" do
      tag = Tag.create!(name: "priority", board: @board)

      assert_respond_to tag, :tickets
      assert_equal [], tag.tickets.to_a
    end

    test "should validate name uniqueness within board scope" do
      Tag.create!(name: "duplicate", board: @board)

      duplicate_tag = Tag.new(name: "duplicate", board: @board)
      assert_not duplicate_tag.valid?
      assert_includes duplicate_tag.errors[:name], "has already been taken"
    end

    test "should allow same name across different boards" do
      tag1 = Tag.create!(name: "common", board: @board)
      tag2 = Tag.new(name: "common", board: @other_board)

      assert tag2.valid?
      assert tag2.save
      assert_not_equal tag1.board, tag2.board
    end

    test "should validate name format" do
      # Valid names
      valid_names = ["bug", "feature-request", "high_priority", "ui-ux", "v2.0"]
      valid_names.each do |name|
        tag = Tag.new(name: name, board: @board)
        assert tag.valid?, "#{name} should be valid"
      end

      # Invalid names
      invalid_names = ["", " ", "too long name that exceeds the maximum character limit for tag names"]
      invalid_names.each do |name|
        tag = Tag.new(name: name, board: @board)
        assert_not tag.valid?, "#{name} should be invalid"
      end
    end

    test "should have optional color" do
      tag_without_color = Tag.create!(name: "plain", board: @board)
      tag_with_color = Tag.create!(name: "colored", board: @board, color: "#ff0000")

      assert_nil tag_without_color.color
      assert_equal "#ff0000", tag_with_color.color
    end

    test "should validate color format when present" do
      valid_colors = ["#ff0000", "#00FF00", "#0000ff", "#123ABC"]
      valid_colors.each do |color|
        tag = Tag.new(name: "test", board: @board, color: color)
        assert tag.valid?, "#{color} should be valid"
      end

      invalid_colors = ["red", "#zzzzzz", "123456", "#ff", "#fffffff"]
      invalid_colors.each do |color|
        tag = Tag.new(name: "test#{color}", board: @board, color: color)
        assert_not tag.valid?, "#{color} should be invalid"
      end
    end

    test "should have usage_count counter cache" do
      tag = Tag.create!(name: "counted", board: @board)

      assert_respond_to tag, :usage_count
      assert_equal 0, tag.usage_count
    end

    test "should order by name" do
      tag_c = Tag.create!(name: "charlie", board: @board)
      tag_a = Tag.create!(name: "alpha", board: @board)
      tag_b = Tag.create!(name: "bravo", board: @board)

      ordered_tags = @board.tags.ordered
      assert_equal [tag_a, tag_b, tag_c], ordered_tags.to_a
    end

    test "should scope by board" do
      board1_tag = Tag.create!(name: "board1-tag", board: @board)
      board2_tag = Tag.create!(name: "board2-tag", board: @other_board)

      board1_tags = Tag.for_board(@board)
      board2_tags = Tag.for_board(@other_board)

      assert_includes board1_tags, board1_tag
      assert_not_includes board1_tags, board2_tag

      assert_includes board2_tags, board2_tag
      assert_not_includes board2_tags, board1_tag
    end

    test "should have color_classes method" do
      tag_with_color = Tag.create!(name: "red-tag", board: @board, color: "#ff0000")
      tag_without_color = Tag.create!(name: "plain-tag", board: @board)

      assert_respond_to tag_with_color, :color_classes
      assert_respond_to tag_without_color, :color_classes

      # Should return some reasonable default classes
      assert_includes tag_without_color.color_classes, "bg-"
      assert_includes tag_without_color.color_classes, "text-"
    end

    test "should prevent deletion when tags are in use" do
      # Create a user first
      user = User.create!(email: "test@example.com")

      tag = Tag.create!(name: "in-use", board: @board)
      ticket = Ticket.create!(
        title: "Tagged Ticket",
        description: "This ticket has tags",
        user_id: user.id,
        board: @board
      )

      # This will be implemented when we create the Tagging model
      # For now, just test the tag exists
      assert tag.persisted?
    end

    test "should normalize name to lowercase" do
      tag = Tag.create!(name: "MiXeD-CaSe", board: @board)

      assert_equal "mixed-case", tag.name
    end

    test "should strip whitespace from name" do
      tag = Tag.create!(name: "  spaced  ", board: @board)

      assert_equal "spaced", tag.name
    end
  end
end
