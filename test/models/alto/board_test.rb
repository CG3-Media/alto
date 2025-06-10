require "test_helper"

module Alto
  class BoardTest < ActiveSupport::TestCase
    test "Board requires name" do
      board = Board.new
      assert_not board.valid?
      assert board.errors[:name].present?
    end

    test "Board generates slug from name automatically" do
      board = Board.new(name: "Test Board with Special Characters!!!")
      assert board.valid?

      board.save!
      assert_equal "test-board-with-special-characters", board.slug
      assert_equal board.slug, board.to_param
    end

    test "Board handles duplicate slugs by adding counter" do
      board1 = Board.create!(name: "Duplicate Name")
      board2 = Board.new(name: "Duplicate Name")

      assert board2.valid?
      board2.save!

      assert_equal "duplicate-name", board1.slug
      assert_equal "duplicate-name-1", board2.slug
    end

    test "Board slug updates when name changes" do
      board = Board.create!(name: "Original Name")
      original_slug = board.slug

      board.update!(name: "Updated Name")
      assert_not_equal original_slug, board.slug
      assert_equal "updated-name", board.slug
    end

    test "Board slug only contains valid characters" do
      board = Board.create!(name: "Test!@#$%^&*()+={}[]|\\:;\"'<>?/.,`~ Board")

      # Should only contain lowercase letters, numbers, hyphens, and underscores
      assert_match /\A[a-z0-9\-_]+\z/, board.slug
      assert_equal "test-board", board.slug
    end

    test "Board by_slug scope works" do
      board = Board.create!(name: "Test Scope Board")
      found_board = Board.by_slug(board.slug).first

      assert_equal board, found_board
    end

    test "Board by_slug scope returns empty when slug not found" do
      boards = Board.by_slug("nonexistent-slug")
      assert_empty boards
    end

    test "Board slug must be unique" do
      board1 = Board.create!(name: "Test Board")
      board2 = Board.create(name: "Different Name")

      # Manually set duplicate slug after creation to test uniqueness
      board2.update(slug: board1.slug)

      assert_not board2.valid?
      assert board2.errors[:slug].present?
    end

    test "Board slug validation format accepts valid slugs" do
      board = Board.create!(name: "Test Board")
      original_slug = board.slug

      # Valid slugs when manually set
      ["test-board-2", "test_board_2", "test123", "another-board-123"].each do |valid_slug|
        board.slug = valid_slug
        assert board.valid?, "#{valid_slug} should be valid, errors: #{board.errors[:slug]}"
      end

      # Restore original slug
      board.slug = original_slug
      assert board.valid?
    end

    test "Board slug validation rejects invalid slugs" do
      board = Board.create!(name: "Test Board")

      # Invalid slugs when manually set
      ["test board", "test@board", "test.board", "Test-Board"].each do |invalid_slug|
        board.slug = invalid_slug
        assert_not board.valid?, "#{invalid_slug} should be invalid"
        assert board.errors[:slug].present?, "#{invalid_slug} should have slug errors"
        board.errors.clear # Clear errors for next iteration
      end
    end

    test "Board can_be_deleted? returns true when no tickets" do
      board = Board.create!(name: "Empty Board")
      assert board.can_be_deleted?
    end

    test "Board tickets_count returns correct count" do
      board = Board.create!(name: "Test Board")
      assert_equal 0, board.tickets_count

      # This would require creating tickets in a real test with proper associations
      # For now, just testing the method exists and returns a number
      assert_kind_of Integer, board.tickets_count
    end

    test "Board has_status_tracking? works correctly" do
      # Use a unique name to avoid conflicts
      status_set = StatusSet.create!(name: "Test Status Set #{Time.current.to_i}")
      board_with_status = Board.create!(name: "Status Board #{Time.current.to_i}", status_set: status_set, item_label_singular: "ticket")

      # Will return false until status_set has statuses
      assert_not board_with_status.has_status_tracking?

      # Add a status and test again
      status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')
      assert board_with_status.has_status_tracking?
    end

    test "Board status-related methods work with empty status sets" do
      status_set = StatusSet.create!(name: "Empty Status Set #{Time.current.to_i}")
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")

      assert_empty board.available_statuses
      assert_empty board.status_options_for_select
      assert_nil board.default_status_slug
      assert_nil board.status_by_slug("any-slug")
    end

    test "Board ordered scope works" do
      board_b = Board.create!(name: "B Board")
      board_a = Board.create!(name: "A Board")
      board_c = Board.create!(name: "C Board")

      ordered_boards = Board.ordered.pluck(:name)
      assert_equal ["A Board", "B Board", "C Board"], ordered_boards
    end

    # Item labeling tests
    test "Board has default item label of ticket" do
      board = Board.create!(name: "Test Board")
      assert_equal "ticket", board.item_name
      assert_equal "tickets", board.item_name.pluralize
      assert_equal "Ticket", board.item_name.capitalize
      assert_equal "Tickets", board.item_name.pluralize.capitalize
    end

    test "Board uses custom item label when set" do
      board = Board.create!(name: "Discussion Board", item_label_singular: "post")
      assert_equal "post", board.item_name
      assert_equal "posts", board.item_name.pluralize
      assert_equal "Post", board.item_name.capitalize
      assert_equal "Posts", board.item_name.pluralize.capitalize
    end

    test "Board handles irregular pluralization correctly" do
      board = Board.create!(name: "Feature Board", item_label_singular: "request")
      assert_equal "request", board.item_name
      assert_equal "requests", board.item_name.pluralize

      # Test a tricky one
      board2 = Board.create!(name: "Bug Board", item_label_singular: "person")
      assert_equal "person", board2.item_name
      assert_equal "people", board2.item_name.pluralize  # Rails pluralize should handle this
    end

    test "Board validates item_label_singular format" do
      board = Board.new(name: "Test Board", item_label_singular: "invalid123!")
      assert_not board.valid?
      assert board.errors[:item_label_singular].present?

      board.item_label_singular = "valid label"
      assert board.valid?
    end

    test "Board requires item_label_singular when set" do
      board = Board.new(name: "Test Board", item_label_singular: "")
      assert_not board.valid?
      assert board.errors[:item_label_singular].present?
    end

    test "Board slug generation handles edge cases" do
      # Empty spaces and special chars only - should fallback to "item"
      board1 = Board.create!(name: "   !@#$%   ")
      assert_equal "item", board1.slug

      # Single character
      board2 = Board.create!(name: "A")
      assert_equal "a", board2.slug

      # Numbers only
      board3 = Board.create!(name: "123")
      assert_equal "123", board3.slug

      # Multiple spaces and hyphens
      board4 = Board.create!(name: "Test   ---   Board")
      assert_equal "test-board", board4.slug
    end

    test "Board has correct item label pluralization" do
      board = Board.create!(name: "Post Board", item_label_singular: "post")
      assert_equal "posts", board.item_name.pluralize
      assert_equal "Posts", board.item_name.pluralize.capitalize
    end

    # Admin-only board tests
    test "Board admin_only? method works correctly" do
      public_board = Board.create!(name: "Public Board", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

      assert_not public_board.admin_only?
      assert admin_board.admin_only?
    end

    test "Board publicly_accessible? method works correctly" do
      public_board = Board.create!(name: "Public Board", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

      assert public_board.publicly_accessible?
      assert_not admin_board.publicly_accessible?
    end

    test "Board scopes work correctly" do
      public_board = Board.create!(name: "Public Board", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

      assert_includes Board.public_boards, public_board
      assert_not_includes Board.public_boards, admin_board

      assert_includes Board.admin_only_boards, admin_board
      assert_not_includes Board.admin_only_boards, public_board
    end

      test "Board accessible_to_user scope works for regular users" do
    public_board = Board.create!(name: "Public Board", is_admin_only: false)
    admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

    accessible_boards = Board.accessible_to_user(nil, current_user_is_admin: false)

    assert_includes accessible_boards, public_board
    assert_not_includes accessible_boards, admin_board
  end

  test "Board accessible_to_user scope works for admin users" do
    public_board = Board.create!(name: "Public Board", is_admin_only: false)
    admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

    accessible_boards = Board.accessible_to_user(nil, current_user_is_admin: true)

    assert_includes accessible_boards, public_board
    assert_includes accessible_boards, admin_board
  end

    test "Board defaults to public when created" do
      board = Board.create!(name: "Default Board")
      assert_not board.admin_only?
      assert board.publicly_accessible?
    end
  end
end
