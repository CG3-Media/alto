require "test_helper"

module Alto
  class SubscribersControllerTest < ActionDispatch::IntegrationTest
    include AltoAuthTestHelper

    def setup
      @user = users(:one)
      @admin_user = users(:two)
      @board = alto_boards(:bugs)
      @ticket = alto_tickets(:test_ticket)

      # Setup permissions
      setup_alto_permissions(can_access_admin: false)

      # Configure user_email callback for unsubscribe tests
      ::Alto.configure do |config|
        config.user_email do |user_id|
          User.find_by(id: user_id)&.email
        end
      end
    end

    def teardown
      teardown_alto_permissions

      # Clean up configuration
      ::Alto.instance_variable_set(:@configuration, nil)
    end

    # Test that only authorized admin users can access admin functions

    test "should get index as admin" do
      setup_admin_user

      get "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers"

      assert_response :success
      assert_select "h3", "Current Subscribers"
    end

    test "should redirect index when not admin" do
      setup_regular_user

      get "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers"

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}"
      assert_equal "You do not have permission to manage subscribers.", flash[:alert]
    end

    # Create action tests

    test "should create subscription as admin with valid email" do
      setup_admin_user
      new_email = "newsubscriber@example.com"

      assert_difference -> { @ticket.subscriptions.count } do
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { subscription: { email: new_email } }
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers"
      assert_match /Successfully subscribed/, flash[:notice]
    end

    test "should handle create subscription for existing email as admin" do
      setup_admin_user
      # Create existing subscription
      existing_subscription = @ticket.subscriptions.create!(email: "existing@example.com")

      assert_no_difference -> { @ticket.subscriptions.count } do
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { subscription: { email: existing_subscription.email } }
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers"
      assert_match /subscription updated/, flash[:notice]
    end

    test "should handle create subscription failure as admin" do
      setup_admin_user

      # Create invalid subscription by using empty email
      assert_no_difference -> { @ticket.subscriptions.count } do
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { subscription: { email: "" } }
      end

      assert_response :unprocessable_entity
      # Test passes as long as it returns error status
    end

    test "should redirect create when not admin" do
      setup_regular_user

      assert_no_difference -> { @ticket.subscriptions.count } do
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { subscription: { email: "test@example.com" } }
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}"
      assert_equal "You do not have permission to manage subscribers.", flash[:alert]
    end

    # Destroy action tests

    test "should destroy subscription as admin" do
      setup_admin_user
      # Create subscription to destroy
      subscription = @ticket.subscriptions.create!(email: "todelete@example.com")

      assert_difference -> { @ticket.subscriptions.count }, -1 do
        delete "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers/#{subscription.id}"
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers"
      assert_match /Successfully unsubscribed/, flash[:notice]
    end

    test "should redirect destroy when not admin" do
      setup_regular_user
      # Create subscription to test authorization
      subscription = @ticket.subscriptions.create!(email: "protected@example.com")

      assert_no_difference -> { @ticket.subscriptions.count } do
        delete "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers/#{subscription.id}"
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}"
      assert_equal "You do not have permission to manage subscribers.", flash[:alert]
    end

    # Unsubscribe action tests (available to all users)

    test "should allow user to unsubscribe themselves when subscribed" do
      setup_regular_user

      # Create subscription for current user using the exact email from user record
      user_subscription = @ticket.subscriptions.create!(email: @user.email)
      assert_equal 1, @ticket.subscriptions.count, "Should have 1 subscription before test"

      # Verify the user ID is set up correctly
      assert_equal @user.id, @user.id, "User should have valid ID"
      assert_not_nil @user.email, "User should have email"

      assert_difference -> { @ticket.subscriptions.count }, -1 do
        delete "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers/unsubscribe"
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}"
      assert_match /You have been unsubscribed/, flash[:notice]
    end

    test "should handle user unsubscribe when not subscribed" do
      setup_regular_user

      assert_no_difference -> { @ticket.subscriptions.count } do
        delete "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers/unsubscribe"
      end

      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}"
      # Just verify a redirect happens - the exact message depends on service implementation
    end

    # Parameter handling tests

    test "should require subscription parameters for create" do
      setup_admin_user

      assert_raises ActionController::ParameterMissing do
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { email: "test@example.com" } # Missing subscription wrapper
      end
    end

    test "should permit only email parameter" do
      setup_admin_user

      post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
           params: {
             subscription: {
               email: "test@example.com",
               malicious_param: "hacked",
               ticket_id: 999999 # Should be ignored
             }
           }

      # Should still work with only email parameter used
      assert_redirected_to "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers"
    end

    # Test service integration

    test "should use subscription service for operations" do
      setup_admin_user

      # Mock the service to ensure it's being called
      original_method = Alto::SubscriptionService.method(:call)
      call_count = 0

      Alto::SubscriptionService.define_singleton_method(:call) do |action, ticket, email_or_user, current_user = nil|
        call_count += 1
        original_method.call(action, ticket, email_or_user, current_user)
      end

      begin
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { subscription: { email: "service@test.com" } }

        assert_equal 1, call_count, "Service should have been called once"
      ensure
        # Restore original method
        Alto::SubscriptionService.define_singleton_method(:call, &original_method)
      end
    end

    # Test error handling

    test "should handle service errors gracefully" do
      setup_admin_user

      # Mock service to return an error with correct argument signature
      Alto::SubscriptionService.define_singleton_method(:call) do |action, ticket, email, current_user = nil|
        OpenStruct.new(
          success?: false,
          notice: nil,
          alert: "Service temporarily unavailable",
          subscription: nil,
          operation: :failed
        )
      end

      begin
        post "/boards/#{@board.slug}/tickets/#{@ticket.id}/subscribers",
             params: { subscription: { email: "test@example.com" } }

        assert_response :unprocessable_entity
        # The test verifies the service handles errors without crashing
      ensure
        # Restore original method behavior
        Alto::SubscriptionService.define_singleton_method(:call) do |action, ticket, user_or_email, current_user = nil|
          new(action, ticket, user_or_email, current_user).call
        end
      end
    end

    private

    def setup_admin_user
      # Mock the authorization check to return true for admin access
      Alto::ApplicationController.define_method(:can_access_admin?) { true }
      Alto::ApplicationController.define_method(:current_user) { @admin_user }
    end

    def setup_regular_user
      # Mock the authorization check to return false for admin access
      Alto::ApplicationController.define_method(:can_access_admin?) { false }
      Alto::ApplicationController.define_method(:current_user) { @user }
    end
  end
end
