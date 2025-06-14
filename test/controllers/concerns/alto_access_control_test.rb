require "test_helper"

class AltoAccessControlTest < ActiveSupport::TestCase
  # Minimal test controller to include the concern
  class TestController < ActionController::Base
    include AltoAccessControl

    attr_accessor :redirects, :access_allowed

    def initialize
      @redirects = []
      @access_allowed = true
    end

    def redirect_to(path, options = {})
      @redirects << { path: path, options: options }
    end

    def can_access_alto?
      @access_allowed
    end

    def alto_home_path
      "/alto"
    end
  end

  test "check_alto_access! allows when access granted" do
    controller = TestController.new
    controller.access_allowed = true

    controller.send(:check_alto_access!)

    assert_empty controller.redirects, "Should not redirect when access granted"
  end

  test "check_alto_access! redirects when access denied" do
    controller = TestController.new
    controller.access_allowed = false

    controller.send(:check_alto_access!)

    assert_equal 1, controller.redirects.length
    redirect = controller.redirects.first
    assert_equal "/alto", redirect[:path]
    assert_equal "You do not have access to Alto", redirect[:options][:alert]
  end
end
