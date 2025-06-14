require "test_helper"

module Alto
  class BoardActivityLoaderTest < ActiveSupport::TestCase
    test "loads board activity data structure" do
      board = Alto::Board.new(name: "Test Board")
      loader = BoardActivityLoader.new(board)

      result = loader.load

      assert_kind_of Hash, result
      assert_includes result.keys, :recent_tickets
      assert_includes result.keys, :recent_comments
      assert_includes result.keys, :recent_upvotes
    end

    test "handles board with no activity gracefully" do
      board = Alto::Board.new(name: "Empty Board")
      loader = BoardActivityLoader.new(board)

      result = loader.load

      # Should return empty collections, not nil
      assert_respond_to result[:recent_tickets], :each
      assert_respond_to result[:recent_comments], :each
      assert_respond_to result[:recent_upvotes], :each
    end
  end
end
