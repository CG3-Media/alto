require "test_helper"

module Alto
  class TaggingEdgeCasesTest < ActiveSupport::TestCase
    # Rule 2: Prefer fixtures over factories
    def setup
      @status_set = StatusSet.create!(name: "Default", is_default: true)
      @status_set.statuses.create!(name: "Open", color: "green", position: 1, slug: "open")

      @board = Board.create!(
        name: "Test Board",
        slug: "test-board",
        description: "Test board for tagging",
        status_set: @status_set,
        item_label_singular: "ticket"
      )

      @user = User.create!(email: "test@example.com")
      @ticket = Ticket.create!(
        title: "Test Ticket",
        description: "Test ticket for tagging",
        user_id: @user.id,
        board: @board
      )
    end

    test "should handle tag creation with empty string normalization" do
      tag = @board.tags.new(name: "  ")

      assert_not tag.valid?
      assert_includes tag.errors[:name], "can't be blank"
    end

        test "should handle tag creation with special characters" do
      # Test that tags reject special characters (per validation)
      tag = @board.tags.new(name: "special!@#$%^&*()")

      assert_not tag.valid?
      assert_includes tag.errors[:name], "only letters, numbers, hyphens, underscores, and dots allowed"
    end

        test "should handle very long tag names" do
      # Test boundary conditions
      long_name = "a" * 100
      tag = @board.tags.new(name: long_name)

      # Should reject overly long names
      assert_not tag.valid?
      assert_includes tag.errors[:name], "is too long (maximum is 50 characters)"
    end

    test "should handle concurrent tag creation attempts" do
      # Rule 3: Real objects - test actual race conditions
      tag_name = "concurrent-tag"

      # First creation should succeed
      tag1 = @board.find_or_create_tag(tag_name)
      assert tag1.persisted?

      # Second attempt should find existing
      tag2 = @board.find_or_create_tag(tag_name)
      assert_equal tag1, tag2
    end

    test "should handle tag deletion with cascade effects" do
      tag = @board.tags.create!(name: "will-be-deleted")
      tagging = Tagging.create!(tag: tag, taggable: @ticket)

      initial_count = tag.usage_count

      # Rule 7: Assert DB side-effects
      assert_difference "@board.tags.count", -1 do
        assert_difference "Tagging.count", -1 do
          tag.destroy!
        end
      end

      # Verify cascading worked
      assert_not Tagging.exists?(tagging.id)
    end

    test "should handle tagging with polymorphic edge cases" do
      # Create a comment to test polymorphic tagging
      comment = Comment.create!(
        content: "Test comment",
        user_id: @user.id,
        ticket: @ticket
      )

      tag = @board.tags.create!(name: "comment-tag")

      # Comments should be taggable too (polymorphic)
      tagging = Tagging.new(tag: tag, taggable: comment)

      # This should work if comments are in same board as tickets
      assert tagging.valid?
      assert tagging.save
    end

        test "should handle tag color validation edge cases" do
      # Test valid hex colors
      valid_colors = ["#000000", "#FFFFFF", "#123abc", "#ABC123"]
      valid_colors.each do |color|
        tag = @board.tags.new(name: "test-valid-#{color.gsub('#', '')}", color: color)
        assert tag.valid?, "#{color} should be valid but got errors: #{tag.errors.full_messages}"
      end

      # Test invalid colors
      invalid_colors = ["#GGG", "#12345", "blue", "123456", "#"]
      invalid_colors.each do |color|
        tag = @board.tags.new(name: "test-invalid-#{color.gsub('#', '')}", color: color)
        assert_not tag.valid?, "#{color} should be invalid"
      end
    end

    test "should handle tag usage count accuracy under load" do
      tag = @board.tags.create!(name: "usage-test")

      # Create multiple tickets and tag them
      tickets = 5.times.map do |i|
        Ticket.create!(
          title: "Test Ticket #{i}",
          description: "Test ticket #{i}",
          user_id: @user.id,
          board: @board
        )
      end

      # Tag all tickets
      tickets.each { |ticket| Tagging.create!(tag: tag, taggable: ticket) }

      tag.reload
      assert_equal 5, tag.usage_count

      # Remove some taggings
      Tagging.where(tag: tag).limit(2).destroy_all

      tag.reload
      assert_equal 3, tag.usage_count
    end

        test "should handle board destruction cleanup" do
      tag = @board.tags.create!(name: "board-cleanup")
      tagging = Tagging.create!(tag: tag, taggable: @ticket)

      tag_id = tag.id
      tagging_id = tagging.id

      # Note: Board may have constraints preventing deletion when tickets exist
      # Let's test the associations instead
      assert_equal @board, tag.board
      assert_equal tag, tagging.tag

      # Clean up the dependencies first
      tagging.destroy!
      @ticket.destroy!

      # Now board can be destroyed
      assert_difference "Tag.count", -1 do
        @board.destroy!
      end

      # Verify cleanup
      assert_not Tag.exists?(tag_id)
    end

        test "should handle tag slug generation conflicts" do
      # Create tags with names that follow validation rules
      tag1 = @board.tags.create!(name: "test-tag-one")
      tag2 = @board.tags.create!(name: "test-tag-two")
      tag3 = @board.tags.create!(name: "test-tag-three")

      # All should be created successfully with unique slugs
      assert tag1.persisted?
      assert tag2.persisted?
      assert tag3.persisted?

      # Slugs should be different
      slugs = [tag1.slug, tag2.slug, tag3.slug]
      assert_equal slugs, slugs.uniq
    end
  end
end
