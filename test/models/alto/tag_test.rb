require "test_helper"

module Alto
  class TagTest < ActiveSupport::TestCase
    test "fixtures load without foreign key violations" do
      # Just try to access fixtures - will fail if FK violations exist
      assert_not_nil alto_status_sets(:default)
      assert_not_nil alto_statuses(:open)
      assert_not_nil alto_boards(:bugs)
      assert_not_nil users(:one)
    end

    test "status set has statuses" do
      status_set = alto_status_sets(:default)
      assert status_set.statuses.any?
      assert_includes status_set.statuses.map(&:slug), "open"
    end

    test "board has valid status set" do
      board = alto_boards(:bugs)
      assert_not_nil board.status_set
      assert_equal "Default Status Set", board.status_set.name
    end

    test "can create tag on board" do
      board = alto_boards(:bugs)
      tag = board.tags.create!(name: "test-tag")
      assert_not_nil tag
      assert_equal "test-tag", tag.name
      assert_equal board, tag.board
    end
  end
end
