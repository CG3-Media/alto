require "test_helper"

module Alto
  class GlobalActivityLoaderTest < ActiveSupport::TestCase
    test "loads global activity data structure" do
      loader = GlobalActivityLoader.new

      result = loader.load

      assert_kind_of Hash, result
      assert_includes result.keys, :recent_tickets
      assert_includes result.keys, :recent_comments
      assert_includes result.keys, :recent_upvotes
    end

    test "returns enumerable collections" do
      loader = GlobalActivityLoader.new

      result = loader.load

      # Should return collections that can be iterated
      assert_respond_to result[:recent_tickets], :each
      assert_respond_to result[:recent_comments], :each
      assert_respond_to result[:recent_upvotes], :each
    end
  end
end
