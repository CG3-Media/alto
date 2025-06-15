require "test_helper"

class Alto::ViewTypeResolverTest < ActiveSupport::TestCase
  def setup
    @board = Alto::Board.new(slug: "test-board", single_view: nil)
    @session = {}
  end

  test "board enforces single view - returns board single_view" do
    @board.single_view = "card"
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    result = resolver.resolve

    assert_equal "card", result.view_type
    assert_equal false, result.show_toggle
  end

  test "board enforces single view with list - returns list" do
    @board.single_view = "list"
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    result = resolver.resolve

    assert_equal "list", result.view_type
    assert_equal false, result.show_toggle
  end

  test "user explicitly chooses card view - stores preference and returns card" do
    resolver = Alto::ViewTypeResolver.new(@board, "card", @session)

    result = resolver.resolve

    assert_equal "card", result.view_type
    assert_equal true, result.show_toggle
    assert_equal "card", @session.dig(:view_preferences, "test-board")
  end

  test "user explicitly chooses list view - stores preference and returns list" do
    resolver = Alto::ViewTypeResolver.new(@board, "list", @session)

    result = resolver.resolve

    assert_equal "list", result.view_type
    assert_equal true, result.show_toggle
    assert_equal "list", @session.dig(:view_preferences, "test-board")
  end

  test "user explicitly chooses invalid view - defaults to card" do
    resolver = Alto::ViewTypeResolver.new(@board, "invalid", @session)

    result = resolver.resolve

    assert_equal "card", result.view_type
    assert_equal true, result.show_toggle
    assert_equal "card", @session.dig(:view_preferences, "test-board")
  end

  test "no explicit choice but stored preference exists - returns stored preference" do
    @session[:view_preferences] = { "test-board" => "list" }
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    result = resolver.resolve

    assert_equal "list", result.view_type
    assert_equal true, result.show_toggle
  end

  test "no explicit choice and no stored preference - defaults to list" do
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    result = resolver.resolve

    assert_equal "list", result.view_type
    assert_equal true, result.show_toggle
  end

  test "no explicit choice with empty view_preferences hash - defaults to list" do
    @session[:view_preferences] = {}
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    result = resolver.resolve

    assert_equal "list", result.view_type
    assert_equal true, result.show_toggle
  end

  test "stores preference in existing view_preferences hash" do
    @session[:view_preferences] = { "other-board" => "card" }
    resolver = Alto::ViewTypeResolver.new(@board, "list", @session)

    result = resolver.resolve

    assert_equal "list", result.view_type
    assert_equal true, result.show_toggle
    assert_equal "card", @session.dig(:view_preferences, "other-board")
    assert_equal "list", @session.dig(:view_preferences, "test-board")
  end

  test "handles different board slugs correctly" do
    board1 = Alto::Board.new(slug: "board-1", single_view: nil)
    board2 = Alto::Board.new(slug: "board-2", single_view: nil)

    # Set preference for board1
    resolver1 = Alto::ViewTypeResolver.new(board1, "card", @session)
    result1 = resolver1.resolve

    # Set different preference for board2
    resolver2 = Alto::ViewTypeResolver.new(board2, "list", @session)
    result2 = resolver2.resolve

    assert_equal "card", result1.view_type
    assert_equal "list", result2.view_type
    assert_equal "card", @session.dig(:view_preferences, "board-1")
    assert_equal "list", @session.dig(:view_preferences, "board-2")
  end

  test "show_toggle returns false when board enforces single view" do
    @board.single_view = "card"
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    assert_equal false, resolver.show_toggle?
  end

  test "show_toggle returns true when board allows user choice" do
    resolver = Alto::ViewTypeResolver.new(@board, nil, @session)

    assert_equal true, resolver.show_toggle?
  end
end
