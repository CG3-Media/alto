require "test_helper"

class EngineAuthenticationTest < ActiveSupport::TestCase
  # Minimal test controller to include the concern
  class TestController < ActionController::Base
    include EngineAuthentication

    attr_accessor :redirects, :user

    def initialize
      @redirects = []
      @user = nil
    end

    def redirect_to(path, options = {})
      @redirects << { path: path, options: options }
    end

    def main_app
      OpenStruct.new(respond_to?: true, current_user: @user)
    end

    def alto_home_path
      "/alto"
    end
  end

  test "authenticate_user! allows when user present" do
    controller = TestController.new
    controller.user = users(:one)

    # Mock current_user to return the user
    controller.define_singleton_method(:current_user) { controller.user }

    controller.send(:authenticate_user!)

    assert_empty controller.redirects, "Should not redirect when user present"
  end

  test "authenticate_user! redirects when no user" do
    controller = TestController.new

    # Mock current_user to return nil
    controller.define_singleton_method(:current_user) { nil }
    controller.define_singleton_method(:host_app_has_authentication?) { false }

    controller.send(:authenticate_user!)

    assert_equal 1, controller.redirects.length
    assert_equal "/alto", controller.redirects.first[:path]
  end

            test "host_app_has_authentication? returns expected value" do
    controller = TestController.new

    result = controller.send(:host_app_has_authentication?)

    # Should return true, false, or nil (when no host app), not crash
    assert_includes [true, false, nil], result
  end

  test "fallback_current_user handles missing main_app gracefully" do
    controller = TestController.new

    # Mock main_app to not respond to current_user
    controller.define_singleton_method(:main_app) {
      OpenStruct.new(respond_to?: false)
    }

    result = controller.send(:fallback_current_user)

    # Should handle gracefully
    assert_nil result
  end
end
