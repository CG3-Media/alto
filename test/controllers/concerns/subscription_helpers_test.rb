require 'test_helper'

class SubscriptionHelpersTest < ActiveSupport::TestCase
  include AltoAuthTestHelper

  # Create a test class that includes the concern
  class TestController < ActionController::Base
    include SubscriptionHelpers

    attr_accessor :current_user

    def initialize(user = nil)
      super()
      @current_user = user
    end

    # Mock helper_method to avoid ActionController dependency in tests
    def self.helper_method(*methods)
      # No-op for testing
    end

    # Expose instance variables for testing
    def set_instance_variable(name, value)
      instance_variable_set(name, value)
    end
  end

  def setup
    setup_alto_permissions
    @user = users(:one)
    @board = alto_boards(:bugs)
    @ticket = alto_tickets(:test_ticket)
    @controller = TestController.new(@user)
  end

  def teardown
    teardown_alto_permissions
  end

  test "current_user_subscribed? returns true when user is subscribed" do
    # Create a subscription for the user
    subscription = @ticket.subscriptions.create!(email: @user.email)

    result = @controller.current_user_subscribed?(@ticket)

    assert result, "Should return true when user is subscribed"
  end

  test "current_user_subscribed? returns false when user is not subscribed" do
    # Ensure no subscription exists
    @ticket.subscriptions.where(email: @user.email).destroy_all

    result = @controller.current_user_subscribed?(@ticket)

    assert_not result, "Should return false when user is not subscribed"
  end

  test "current_user_subscribed? uses @ticket instance variable when no ticket parameter provided" do
    # Set up @ticket instance variable
    @controller.set_instance_variable(:@ticket, @ticket)
    @ticket.subscriptions.create!(email: @user.email)

    result = @controller.current_user_subscribed?

    assert result, "Should use @ticket instance variable and return true"
  end

  test "current_user_subscribed? returns false when no current_user" do
    controller_without_user = TestController.new(nil)

    result = controller_without_user.current_user_subscribed?(@ticket)

    assert_not result, "Should return false when no current_user"
  end

  test "current_user_subscribed? returns false when no ticket provided" do
    result = @controller.current_user_subscribed?(nil)

    assert_not result, "Should return false when no ticket provided"
  end

  test "current_user_subscribed? returns false when user_email is blank" do
    # Configure user_email to return blank
    ::Alto.configure do |config|
      config.user_email do |user_id|
        ""  # Blank email
      end
    end

    result = @controller.current_user_subscribed?(@ticket)

    assert_not result, "Should return false when user email is blank"
  end

  test "current_user_subscribed? returns false when user_email is nil" do
    # Configure user_email to return nil
    ::Alto.configure do |config|
      config.user_email do |user_id|
        nil
      end
    end

    result = @controller.current_user_subscribed?(@ticket)

    assert_not result, "Should return false when user email is nil"
  end

  test "current_user_subscribed? handles exceptions gracefully" do
    # Configure user_email to raise an exception
    ::Alto.configure do |config|
      config.user_email do |user_id|
        raise StandardError, "Database connection failed"
      end
    end

    # Should not raise exception and return false
    result = @controller.current_user_subscribed?(@ticket)

    assert_not result, "Should return false when exception occurs"
  end

  test "current_user_subscribed? logs warning when exception occurs" do
    # Configure user_email to raise an exception
    ::Alto.configure do |config|
      config.user_email do |user_id|
        raise StandardError, "Test error"
      end
    end

    # Capture log output
    log_output = StringIO.new
    old_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      @controller.current_user_subscribed?(@ticket)

      log_content = log_output.string
      assert_includes log_content, "[Alto] Failed to check subscription status: Test error"
    ensure
      Rails.logger = old_logger
    end
  end

  test "current_user_subscribed? works with different user emails" do
    other_email = "other@example.com"
    @ticket.subscriptions.create!(email: other_email)

    # Configure user_email to return the other email
    ::Alto.configure do |config|
      config.user_email do |user_id|
        other_email
      end
    end

    result = @controller.current_user_subscribed?(@ticket)

    assert result, "Should return true when subscription exists for configured email"
  end
end
