require "test_helper"

class TicketPermissionCheckerTest < ActiveSupport::TestCase
  # Minimal test controller to include the concern
  class TestController < ActionController::Base
    include TicketPermissionChecker

    attr_accessor :can_submit_tickets, :redirects

    def initialize
      @can_submit_tickets = false
      @redirects = []
    end

    def can_submit_tickets?
      @can_submit_tickets
    end

    def redirect_to(path, options = {})
      @redirects << { path: path, options: options }
    end
  end

  test "check_submit_permission allows when user can submit tickets" do
    controller = TestController.new
    controller.can_submit_tickets = true

    controller.send(:check_submit_permission)

    assert_empty controller.redirects, "Should not redirect when permission granted"
  end

  test "check_submit_permission redirects when user cannot submit tickets" do
    controller = TestController.new
    controller.can_submit_tickets = false

    controller.send(:check_submit_permission)

    assert_equal 1, controller.redirects.length
    redirect = controller.redirects.first
    assert_equal "You do not have permission to submit tickets", redirect[:options][:alert]
  end
end
