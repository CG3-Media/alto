require "test_helper"

module Alto
  class ActivityTimelineBuilderTest < ActiveSupport::TestCase
    test "builds timeline from empty activity data" do
      activity_data = {
        recent_tickets: [],
        recent_comments: [],
        recent_upvotes: []
      }

      builder = ActivityTimelineBuilder.new(activity_data)
      result = builder.build

      assert_kind_of Array, result
      assert_empty result
    end

    test "builds timeline with board-specific limit" do
      activity_data = {
        recent_tickets: [],
        recent_comments: [],
        recent_upvotes: []
      }
      board = Alto::Board.new(name: "Test Board")

      builder = ActivityTimelineBuilder.new(activity_data, board: board)
      result = builder.build

      assert_kind_of Array, result
    end

    test "handles real ticket objects" do
      ticket = Alto::Ticket.new(
        title: "Test Ticket",
        description: "Test",
        created_at: Time.current
      )

      activity_data = {
        recent_tickets: [ticket],
        recent_comments: [],
        recent_upvotes: []
      }

      builder = ActivityTimelineBuilder.new(activity_data)
      result = builder.build

      assert_equal 1, result.length
      assert_equal :ticket_created, result.first[:type]
    end
  end
end
