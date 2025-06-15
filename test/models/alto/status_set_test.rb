require "test_helper"

module Alto
  class StatusSetTest < ActiveSupport::TestCase
    def setup
      @status_set = alto_status_sets(:default)
    end

    test "ensure_status_positions! should work with existing positioned statuses" do
      # Create status set with already-positioned statuses
      status_set = StatusSet.create!(name: "Test Set", description: "Testing positions")

      status1 = status_set.statuses.create!(name: "Open", slug: "open", color: "red", position: 0)
      status2 = status_set.statuses.create!(name: "Closed", slug: "closed", color: "green", position: 1)
      status3 = status_set.statuses.create!(name: "In Progress", slug: "in_progress", color: "blue", position: 2)

      # Call ensure_status_positions! (should not change anything)
      status_set.ensure_status_positions!

      # Positions should remain the same
      assert_equal 0, status1.reload.position
      assert_equal 1, status2.reload.position
      assert_equal 2, status3.reload.position
    end

    test "ensure_status_positions! should not change existing positions" do
      # Create status set with statuses that already have positions
      status_set = StatusSet.create!(name: "Positioned Set", description: "Already has positions")

      status1 = status_set.statuses.create!(name: "Open", slug: "open", color: "red", position: 5)
      status2 = status_set.statuses.create!(name: "Closed", slug: "closed", color: "green", position: 10)
      status3 = status_set.statuses.create!(name: "In Progress", slug: "in_progress", color: "blue", position: 15)

      # Call ensure_status_positions!
      status_set.ensure_status_positions!

      # Positions should remain unchanged
      assert_equal 5, status1.reload.position
      assert_equal 10, status2.reload.position
      assert_equal 15, status3.reload.position
    end

    test "ensure_status_positions! should work correctly with normal status creation" do
      # Create status set and test normal behavior
      status_set = StatusSet.create!(name: "Mixed Set", description: "Normal status creation")

      # Create statuses with normal positions
      status1 = status_set.statuses.create!(name: "Open", slug: "open", color: "red", position: 10)
      status2 = status_set.statuses.create!(name: "Closed", slug: "closed", color: "green", position: 5)

      # Call ensure_status_positions! (should not change existing positions)
      status_set.ensure_status_positions!

      # Positions should remain unchanged
      assert_equal 10, status1.reload.position
      assert_equal 5, status2.reload.position
    end

    test "ensure_status_positions! should handle status set with no statuses" do
      # Create empty status set
      empty_set = StatusSet.create!(name: "Empty Set", description: "No statuses")

      # Should not raise error
      assert_nothing_raised do
        empty_set.ensure_status_positions!
      end
    end
  end
end
