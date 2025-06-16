require 'test_helper'

class Alto::BoardHelperTest < ActionView::TestCase
  include Alto::BoardHelper

  def setup
    @board = alto_boards(:bugs)
    @ticket = alto_tickets(:test_ticket)
  end

  test "board_item_name returns board's item name when present" do
    result = board_item_name(@board)
    assert_equal "bug", result  # From fixture
  end

  test "board_item_name returns default when board has no item name" do
    board_without_label = Object.new
    board_without_label.define_singleton_method(:item_name) { nil }

    result = board_item_name(board_without_label)
    assert_equal "ticket", result
  end

  test "board_item_name handles nil board gracefully" do
    result = board_item_name(nil)
    assert_equal "ticket", result
  end

  test "board_allows_voting? returns true for tickets when board allows voting" do
    # Test with the existing board from fixture which has allow_voting: true
    result = board_allows_voting?(@ticket)
    assert result
  end

  test "board_allows_voting? always returns true for comments" do
    comment = Object.new
    comment.define_singleton_method(:is_a?) { |klass| klass.name == 'Alto::Comment' }

    result = board_allows_voting?(comment)
    assert result
  end

  test "board_allows_voting? returns true for unknown types" do
    unknown_object = Object.new

    result = board_allows_voting?(unknown_object)
    assert result
  end
end
