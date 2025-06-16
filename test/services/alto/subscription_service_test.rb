require "test_helper"

module Alto
  class SubscriptionServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:one)
      @board = alto_boards(:bugs)
      @ticket = alto_tickets(:test_ticket)

      # Configure user_email callback for tests
      ::Alto.configure do |config|
        config.user_email do |user_id|
          User.find_by(id: user_id)&.email
        end
      end
    end

    def teardown
      # Clean up configuration
      ::Alto.instance_variable_set(:@configuration, nil)
    end

    # Subscribe action tests

    test "should successfully subscribe new email to ticket" do
      email = "newuser@example.com"

      assert_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:subscribe, @ticket, email)

        assert result.success?
        assert_equal "Successfully subscribed #{email} to this ticket.", result.notice
        assert_nil result.alert
        assert_equal :created, result.operation
        assert_kind_of Subscription, result.subscription
        assert_equal email, result.subscription.email
        assert_equal @ticket, result.subscription.ticket
      end
    end

    test "should update existing subscription when subscribing existing email" do
      # Create existing subscription
      existing_subscription = @ticket.subscriptions.create!(email: "existing@example.com")
      original_updated_at = existing_subscription.updated_at

      # Wait a moment to ensure timestamps differ
      travel 1.second do
        assert_no_difference -> { @ticket.subscriptions.count } do
          result = SubscriptionService.call(:subscribe, @ticket, existing_subscription.email)

          assert result.success?
          assert_equal "#{existing_subscription.email} subscription updated. They can continue receiving notifications for this ticket.", result.notice
          assert_nil result.alert
          assert_equal :updated, result.operation
          assert_equal existing_subscription, result.subscription

          # Verify timestamp was updated
          existing_subscription.reload
          assert_not_equal original_updated_at, existing_subscription.updated_at
        end
      end
    end

    test "should fail to subscribe invalid email" do
      assert_no_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:subscribe, @ticket, "invalid-email")

        refute result.success?
        assert_equal "Failed to create subscription.", result.alert
        assert_nil result.notice
        assert_equal :failed, result.operation
        assert_kind_of Subscription, result.subscription
        refute result.subscription.persisted?
      end
    end

    # Unsubscribe action tests

    test "should successfully unsubscribe existing email from ticket" do
      # Create subscription to unsubscribe
      existing_subscription = @ticket.subscriptions.create!(email: "toremove@example.com")

      assert_difference -> { @ticket.subscriptions.count }, -1 do
        result = SubscriptionService.call(:unsubscribe, @ticket, existing_subscription.email)

        assert result.success?
        assert_equal "Successfully unsubscribed #{existing_subscription.email} from this ticket.", result.notice
        assert_nil result.alert
        assert_equal :destroyed, result.operation
        assert_equal existing_subscription, result.subscription
      end
    end

    test "should fail to unsubscribe non-existent email" do
      non_existent_email = "notsubscribed@example.com"

      assert_no_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:unsubscribe, @ticket, non_existent_email)

        refute result.success?
        assert_equal "#{non_existent_email} is not subscribed to this ticket.", result.alert
        assert_nil result.notice
        assert_equal :failed, result.operation
        assert_nil result.subscription
      end
    end

    # Unsubscribe user action tests

    test "should successfully unsubscribe current user when subscribed" do
      # Create subscription for current user
      user_subscription = @ticket.subscriptions.create!(email: @user.email)

      assert_difference -> { @ticket.subscriptions.count }, -1 do
        result = SubscriptionService.call(:unsubscribe_user, @ticket, nil, @user)

        assert result.success?
        assert_equal "You have been unsubscribed from this ticket.", result.notice
        assert_nil result.alert
        assert_equal :destroyed, result.operation
        assert_equal user_subscription, result.subscription
      end
    end

    test "should handle unsubscribe when user not subscribed" do
      assert_no_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:unsubscribe_user, @ticket, nil, @user)

        assert result.success?
        assert_equal "You are not currently subscribed to this ticket.", result.notice
        assert_nil result.alert
        assert_equal :not_found, result.operation
        assert_nil result.subscription
      end
    end

    test "should fail unsubscribe_user when no current user" do
      assert_no_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:unsubscribe_user, @ticket, nil, nil)

        refute result.success?
        assert_equal "You must be logged in to unsubscribe.", result.alert
        assert_nil result.notice
        assert_equal :failed, result.operation
      end
    end

    test "should handle user email resolution failure" do
      # Configure user_email to return nil
      ::Alto.configure do |config|
        config.user_email { |user_id| nil }
      end

      assert_no_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:unsubscribe_user, @ticket, nil, @user)

        refute result.success?
        assert_equal "Unable to determine your email address.", result.alert
        assert_nil result.notice
        assert_equal :failed, result.operation
      end
    end

    test "should handle exceptions in unsubscribe_user" do
      # Configure user_email to raise exception
      ::Alto.configure do |config|
        config.user_email { |user_id| raise "Database error" }
      end

      assert_no_difference -> { @ticket.subscriptions.count } do
        result = SubscriptionService.call(:unsubscribe_user, @ticket, nil, @user)

        refute result.success?
        assert_equal "Failed to unsubscribe. Please try again.", result.alert
        assert_nil result.notice
        assert_equal :failed, result.operation
      end
    end

    # Invalid action tests

    test "should fail with invalid action" do
      result = SubscriptionService.call(:invalid_action, @ticket, "test@example.com")

      refute result.success?
      assert_equal "Invalid action: invalid_action", result.alert
      assert_nil result.notice
      assert_equal :failed, result.operation
    end

    # Service object instantiation tests

    test "should initialize with correct attributes" do
      service = SubscriptionService.new(:subscribe, @ticket, "test@example.com", @user)

      assert_equal :subscribe, service.instance_variable_get(:@action)
      assert_equal @ticket, service.instance_variable_get(:@ticket)
      assert_equal "test@example.com", service.instance_variable_get(:@user_or_email)
      assert_equal @user, service.instance_variable_get(:@current_user)
    end

    test "should convert action to symbol" do
      service = SubscriptionService.new("subscribe", @ticket, "test@example.com")

      assert_equal :subscribe, service.instance_variable_get(:@action)
    end
  end
end
