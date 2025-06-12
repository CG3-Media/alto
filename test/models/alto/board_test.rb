require "test_helper"

module Alto
  class BoardTest < ActiveSupport::TestCase
    test "Board requires name" do
      board = Board.new
      assert_not board.valid?
      assert board.errors[:name].present?
    end

    test "Board generates slug from name automatically" do
      status_set = alto_status_sets(:default)
      board = Board.new(name: "Test Board with Special Characters!!!", status_set: status_set, item_label_singular: "ticket")
      assert board.valid?

      board.save!
      assert_equal "test-board-with-special-characters", board.slug
      assert_equal board.slug, board.to_param
    end

    test "Board handles duplicate slugs by adding counter" do
      status_set = alto_status_sets(:default)
      board1 = Board.create!(name: "Duplicate Name", status_set: status_set, item_label_singular: "ticket")
      board2 = Board.new(name: "Duplicate Name", status_set: status_set, item_label_singular: "ticket")

      assert board2.valid?
      board2.save!

      assert_equal "duplicate-name", board1.slug
      assert_equal "duplicate-name-1", board2.slug
    end

    test "Board slug updates when name changes" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Original Name", status_set: status_set, item_label_singular: "ticket")
      original_slug = board.slug

      board.update!(name: "Updated Name")
      assert_not_equal original_slug, board.slug
      assert_equal "updated-name", board.slug
    end

    test "Board slug only contains valid characters" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test!@#$%^&*()+={}[]|\\:;\"'<>?/.,`~ Board", status_set: status_set, item_label_singular: "ticket")

      # Should only contain lowercase letters, numbers, hyphens, and underscores
      assert_match /\A[a-z0-9\-_]+\z/, board.slug
      assert_equal "test-board", board.slug
    end

    test "Board by_slug scope works" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test Scope Board", status_set: status_set, item_label_singular: "ticket")
      found_board = Board.by_slug(board.slug).first

      assert_equal board, found_board
    end

    test "Board by_slug scope returns empty when slug not found" do
      boards = Board.by_slug("nonexistent-slug")
      assert_empty boards
    end

    test "Board slug must be unique" do
      status_set = alto_status_sets(:default)
      board1 = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")
      board2 = Board.create(name: "Different Name", status_set: status_set, item_label_singular: "ticket")

      # Manually set duplicate slug after creation to test uniqueness
      board2.update(slug: board1.slug)

      assert_not board2.valid?
      assert board2.errors[:slug].present?
    end

    test "Board slug validation format accepts valid slugs" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")
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
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")

      # Invalid slugs when manually set
      ["test board", "test@board", "test.board", "Test-Board"].each do |invalid_slug|
        board.slug = invalid_slug
        assert_not board.valid?, "#{invalid_slug} should be invalid"
        assert board.errors[:slug].present?, "#{invalid_slug} should have slug errors"
        board.errors.clear # Clear errors for next iteration
      end
    end

    test "Board can_be_deleted? returns true when no tickets" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Empty Board", status_set: status_set, item_label_singular: "ticket")
      assert board.can_be_deleted?
    end

    test "Board tickets_count returns correct count" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")
      assert_equal 0, board.tickets_count

      # This would require creating tickets in a real test with proper associations
      # For now, just testing the method exists and returns a number
      assert_kind_of Integer, board.tickets_count
    end

    test "Board has_status_tracking? works correctly" do
      # Use a unique name to avoid conflicts
      status_set = Alto::StatusSet.create!(name: "Test Status Set #{Time.current.to_i}")
      board_with_status = Board.create!(name: "Status Board #{Time.current.to_i}", status_set: status_set, item_label_singular: "ticket")

      # Will return false until status_set has statuses
      assert_not board_with_status.has_status_tracking?

      # Add a status and test again
      status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')
      assert board_with_status.has_status_tracking?
    end

    test "Board status-related methods work with empty status sets" do
      status_set = Alto::StatusSet.create!(name: "Empty Status Set #{Time.current.to_i}")
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")

      assert_empty board.available_statuses
      assert_empty board.status_options_for_select
      assert_nil board.default_status_slug
      assert_nil board.status_by_slug("any-slug")
    end

    test "Board ordered scope works" do
      status_set = alto_status_sets(:default)
      board_b = Board.create!(name: "B Board", status_set: status_set, item_label_singular: "ticket")
      board_a = Board.create!(name: "A Board", status_set: status_set, item_label_singular: "ticket")
      board_c = Board.create!(name: "C Board", status_set: status_set, item_label_singular: "ticket")

      # Get all board names in order and filter to just the ones we created
      all_ordered_boards = Board.ordered.pluck(:name)
      created_board_names = ["A Board", "B Board", "C Board"]
      ordered_created_boards = all_ordered_boards.select { |name| created_board_names.include?(name) }

      assert_equal ["A Board", "B Board", "C Board"], ordered_created_boards
    end

    # Item labeling tests
    test "Board has default item label of ticket" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")
      assert_equal "ticket", board.item_name
      assert_equal "tickets", board.item_name.pluralize
      assert_equal "Ticket", board.item_name.capitalize
      assert_equal "Tickets", board.item_name.pluralize.capitalize
    end

    test "Board uses custom item label when set" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Discussion Board", status_set: status_set, item_label_singular: "post")
      assert_equal "post", board.item_name
      assert_equal "posts", board.item_name.pluralize
      assert_equal "Post", board.item_name.capitalize
      assert_equal "Posts", board.item_name.pluralize.capitalize
    end

    test "Board handles irregular pluralization correctly" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Feature Board", status_set: status_set, item_label_singular: "request")
      assert_equal "request", board.item_name
      assert_equal "requests", board.item_name.pluralize

      # Test a tricky one
      board2 = Board.create!(name: "Bug Board", status_set: status_set, item_label_singular: "person")
      assert_equal "person", board2.item_name
      assert_equal "people", board2.item_name.pluralize  # Rails pluralize should handle this
    end

    test "Board validates item_label_singular format" do
      status_set = alto_status_sets(:default)
      board = Board.new(name: "Test Board", status_set: status_set, item_label_singular: "invalid123!")
      assert_not board.valid?
      assert board.errors[:item_label_singular].present?

      board.item_label_singular = "valid label"
      assert board.valid?
    end

    # Field relationship tests
    test "Board has many fields" do
      board = alto_boards(:bugs)
      assert_respond_to board, :fields
      assert_kind_of ActiveRecord::Associations::CollectionProxy, board.fields
    end

    test "Board destroys fields when destroyed" do
      board = alto_boards(:bugs)
      field = board.fields.create!(label: "Test Field", field_type: "text_input")
      field_id = field.id

      board.destroy
      assert_not Alto::Field.exists?(field_id)
    end

    test "Board can have multiple fields" do
      board = alto_boards(:bugs)

      field1 = board.fields.create!(label: "Priority", field_type: "select", field_options: ["Low", "High"])
      field2 = board.fields.create!(label: "Description", field_type: "textarea")

      assert_equal 2, board.fields.count
      assert_includes board.fields, field1
      assert_includes board.fields, field2
    end

    test "Board requires item_label_singular when set" do
      status_set = alto_status_sets(:default)
      board = Board.new(name: "Test Board", status_set: status_set, item_label_singular: "")
      assert_not board.valid?
      assert board.errors[:item_label_singular].present?
    end

    test "Board slug generation handles edge cases" do
      status_set = alto_status_sets(:default)
      # Empty spaces and special chars only - should fallback to "item"
      board1 = Board.create!(name: "   !@#$%   ", status_set: status_set, item_label_singular: "ticket")
      assert_equal "item", board1.slug

      # Single character
      board2 = Board.create!(name: "A", status_set: status_set, item_label_singular: "ticket")
      assert_equal "a", board2.slug

      # Numbers only
      board3 = Board.create!(name: "123", status_set: status_set, item_label_singular: "ticket")
      assert_equal "123", board3.slug

      # Multiple spaces and hyphens
      board4 = Board.create!(name: "Test   ---   Board", status_set: status_set, item_label_singular: "ticket")
      assert_equal "test-board", board4.slug
    end

    test "Board has correct item label pluralization" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Post Board", status_set: status_set, item_label_singular: "post")
      assert_equal "posts", board.item_name.pluralize
      assert_equal "Posts", board.item_name.pluralize.capitalize
    end

    # Admin-only board tests
    test "Board admin_only? method works correctly" do
      status_set = alto_status_sets(:default)
      public_board = Board.create!(name: "Public Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: true)

      assert_not public_board.admin_only?
      assert admin_board.admin_only?
    end

    test "Board publicly_accessible? method works correctly" do
      status_set = alto_status_sets(:default)
      public_board = Board.create!(name: "Public Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: true)

      assert public_board.publicly_accessible?
      assert_not admin_board.publicly_accessible?
    end

    test "Board scopes work correctly" do
      status_set = alto_status_sets(:default)
      public_board = Board.create!(name: "Public Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: true)

      assert_includes Board.public_boards, public_board
      assert_not_includes Board.public_boards, admin_board

      assert_includes Board.admin_only_boards, admin_board
      assert_not_includes Board.admin_only_boards, public_board
    end

    test "Board accessible_to_user scope works for regular users" do
      status_set = alto_status_sets(:default)
      public_board = Board.create!(name: "Public Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: true)

      accessible_boards = Board.accessible_to_user(nil, current_user_is_admin: false)

      assert_includes accessible_boards, public_board
      assert_not_includes accessible_boards, admin_board
    end

    test "Board accessible_to_user scope works for admin users" do
      status_set = alto_status_sets(:default)
      public_board = Board.create!(name: "Public Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: false)
      admin_board = Board.create!(name: "Admin Board", status_set: status_set, item_label_singular: "ticket", is_admin_only: true)

      accessible_boards = Board.accessible_to_user(nil, current_user_is_admin: true)

      assert_includes accessible_boards, public_board
      assert_includes accessible_boards, admin_board
    end

    test "Board defaults to public when created" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Default Board", status_set: status_set, item_label_singular: "ticket")
      assert_not board.admin_only?
      assert board.publicly_accessible?
    end

        # Single view tests
    test "Board single_view enum accepts valid values" do
      status_set = alto_status_sets(:default)

      # Test card view
      card_board = Board.create!(name: "Card Board", status_set: status_set, item_label_singular: "ticket", single_view: "card")
      assert_equal "card", card_board.single_view
      assert card_board.card_single_view?
      assert_not card_board.list_single_view?

      # Test list view
      list_board = Board.create!(name: "List Board", status_set: status_set, item_label_singular: "ticket", single_view: "list")
      assert_equal "list", list_board.single_view
      assert list_board.list_single_view?
      assert_not list_board.card_single_view?
    end

    test "Board single_view defaults to nil when not specified" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Flexible Board", status_set: status_set, item_label_singular: "ticket")

      assert_nil board.single_view
      assert_not board.card_single_view?
      assert_not board.list_single_view?
    end

    test "Board single_view can be set to nil/blank for flexible viewing" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket", single_view: "card")

      # Verify it starts as card
      assert board.card_single_view?

      # Change to nil
      board.update!(single_view: nil)
      assert_nil board.single_view
      assert_not board.card_single_view?
      assert_not board.list_single_view?

      # Change to blank string (Rails converts to nil for enums)
      board.update!(single_view: "")
      assert_nil board.single_view
      assert_not board.card_single_view?
      assert_not board.list_single_view?
    end

    test "Board single_view rejects invalid values" do
      status_set = alto_status_sets(:default)
      board = Board.new(name: "Test Board", status_set: status_set, item_label_singular: "ticket")

      # Invalid enum values should raise an error
      assert_raises(ArgumentError) do
        board.single_view = "invalid"
      end

      assert_raises(ArgumentError) do
        board.single_view = "grid"
      end

      assert_raises(ArgumentError) do
        board.single_view = "table"
      end
    end

        test "Board allows_view_toggle? method works correctly" do
      status_set = alto_status_sets(:default)

      # Board with no single_view set should allow toggle
      flexible_board = Board.create!(name: "Flexible Board", status_set: status_set, item_label_singular: "ticket")
      assert flexible_board.allows_view_toggle?

      # Board with blank single_view should allow toggle
      flexible_board.update!(single_view: "")
      assert flexible_board.allows_view_toggle?

      # Board with card view enforced should not allow toggle
      card_board = Board.create!(name: "Card Board", status_set: status_set, item_label_singular: "ticket", single_view: "card")
      assert_not card_board.allows_view_toggle?

      # Board with list view enforced should not allow toggle
      list_board = Board.create!(name: "List Board", status_set: status_set, item_label_singular: "ticket", single_view: "list")
      assert_not list_board.allows_view_toggle?
    end

    test "Board enforced_view_type method returns correct values" do
      status_set = alto_status_sets(:default)

      # Board with no single_view set should return nil
      flexible_board = Board.create!(name: "Flexible Board", status_set: status_set, item_label_singular: "ticket")
      assert_nil flexible_board.enforced_view_type

      # Board with blank single_view should return nil
      flexible_board.update!(single_view: "")
      assert_nil flexible_board.enforced_view_type

      # Board with card view should return "card"
      card_board = Board.create!(name: "Card Board", status_set: status_set, item_label_singular: "ticket", single_view: "card")
      assert_equal "card", card_board.enforced_view_type

      # Board with list view should return "list"
      list_board = Board.create!(name: "List Board", status_set: status_set, item_label_singular: "ticket", single_view: "list")
      assert_equal "list", list_board.enforced_view_type
    end

        test "Board single_view can be updated between valid values" do
      status_set = alto_status_sets(:default)
      board = Board.create!(name: "Changeable Board", status_set: status_set, item_label_singular: "ticket")

      # Start with no restriction
      assert_nil board.single_view
      assert board.allows_view_toggle?

      # Change to card view
      board.update!(single_view: "card")
      assert board.card_single_view?
      assert_not board.allows_view_toggle?
      assert_equal "card", board.enforced_view_type

      # Change to list view
      board.update!(single_view: "list")
      assert board.list_single_view?
      assert_not board.allows_view_toggle?
      assert_equal "list", board.enforced_view_type

      # Change back to flexible
      board.update!(single_view: nil)
      assert_nil board.single_view
      assert board.allows_view_toggle?
      assert_nil board.enforced_view_type
    end

    test "Board single_view works with mass assignment" do
      status_set = alto_status_sets(:default)

      # Test creation with card view
      card_board = Board.create!(
        name: "Card Board",
        status_set: status_set,
        item_label_singular: "ticket",
        single_view: "card"
      )
      assert card_board.card_single_view?

      # Test creation with list view
      list_board = Board.create!(
        name: "List Board",
        status_set: status_set,
        item_label_singular: "ticket",
        single_view: "list"
      )
      assert list_board.list_single_view?

      # Test update with single_view
      board = Board.create!(name: "Test Board", status_set: status_set, item_label_singular: "ticket")
      board.update!(single_view: "card")
      assert board.card_single_view?
    end
  end
end
