require "test_helper"

module Alto
  class TicketParameterBuilderTest < ActiveSupport::TestCase
    test "builds basic parameters" do
      user = users(:one)
      params = ActionController::Parameters.new({
        ticket: {
          title: "Test Ticket",
          description: "Test Description"
        }
      })

      builder = TicketParameterBuilder.new(params, user, nil)
      result = builder.build

      assert_equal "Test Ticket", result[:title]
      assert_equal "Test Description", result[:description]
    end

    test "includes admin parameters when admin access granted" do
      user = users(:one)
      params = ActionController::Parameters.new({
        ticket: {
          title: "Test Ticket",
          description: "Test Description",
          status_slug: "open",
          locked: true
        }
      })

      permissions = { can_access_admin: true }
      builder = TicketParameterBuilder.new(params, user, nil, permissions)

      result = builder.build

      assert_equal "open", result[:status_slug]
      assert_equal true, result[:locked]
    end

    test "handles nil permissions gracefully" do
      user = users(:one)
      params = ActionController::Parameters.new({
        ticket: {
          title: "Test Ticket",
          description: "Test Description"
        }
      })

      builder = TicketParameterBuilder.new(params, user, nil, nil)
      result = builder.build

      assert_equal "Test Ticket", result[:title]
      assert_equal "Test Description", result[:description]
    end
  end
end
