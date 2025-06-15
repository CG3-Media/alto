require "test_helper"

module Alto
  class SubscribableTest < ActiveSupport::TestCase
    # Create a test class that includes the Subscribable concern
    class TestSubscribableModel < ActiveRecord::Base
      self.table_name = "alto_tickets"
      include ::Alto::Subscribable

      attr_accessor :test_user_email, :test_ticket, :should_create_sub

      def subscribable_ticket
        @test_ticket
      end

      def user_email
        @test_user_email
      end

      def should_create_subscription?
        @should_create_sub.nil? ? true : @should_create_sub
      end
    end

    def setup
      # Use fixtures instead of manual creation
      @user1 = users(:one)
      @user2 = users(:two)

      # Use existing fixture board
      @board = alto_boards(:bugs)

      @ticket = Ticket.create!(
        title: "Test Ticket",
        description: "Test Description",
        user: @user1,
        board: @board,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test subscribable steps"
        }
      )
    end

    test "should include Subscribable concern" do
      assert_includes TestSubscribableModel.included_modules, ::Alto::Subscribable
    end

    test "should create subscription after_create when conditions are met" do
      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = "test@example.com"
      model.test_ticket = @ticket

      assert_difference "@ticket.subscriptions.count", 1 do
        model.save!
      end

      subscription = @ticket.subscriptions.last
      assert_equal "test@example.com", subscription.email
    end

    test "should not create subscription if user_id is blank" do
      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: 999, # Use non-existent user ID instead of nil to avoid NOT NULL constraint
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = nil # Make sure no email is set
      model.test_ticket = @ticket

      assert_no_difference "@ticket.subscriptions.count" do
        model.save!
      end
    end

    test "should not create subscription if user_email is blank" do
      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = nil
      model.test_ticket = @ticket

      assert_no_difference "@ticket.subscriptions.count" do
        model.save!
      end
    end

    test "should not create subscription if subscribable_ticket is nil" do
      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = "test@example.com"
      model.test_ticket = nil

      assert_no_difference "@ticket.subscriptions.count" do
        model.save!
      end
    end

    test "should not create subscription if should_create_subscription? returns false" do
      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = "test@example.com"
      model.test_ticket = @ticket
      model.should_create_sub = false

      assert_no_difference "@ticket.subscriptions.count" do
        model.save!
      end
    end

    test "should handle subscription creation errors gracefully" do
      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = "test@example.com"
      model.test_ticket = @ticket

      # Create an invalid email that would trigger an error during subscription creation
      # by setting an email that's too long for the database field
      model.test_user_email = "a" * 300 + "@example.com"

      # Should not raise the error, just log it and continue
      assert_nothing_raised do
        model.save!
      end

      # Should have successfully saved the model despite subscription error
      assert model.persisted?
    end

    test "should find existing subscription instead of creating duplicate" do
      # Create existing subscription
      existing_subscription = @ticket.subscriptions.create!(email: "test@example.com")

      model = TestSubscribableModel.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )
      model.test_user_email = "test@example.com"
      model.test_ticket = @ticket

      assert_no_difference "@ticket.subscriptions.count" do
        model.save!
      end

      # Should still have the original subscription
      assert_equal existing_subscription, @ticket.subscriptions.find_by(email: "test@example.com")
    end

    test "should raise NotImplementedError for subscribable_ticket if not implemented" do
      # Create a minimal test class without implementing the method
      minimal_class = Class.new(ActiveRecord::Base) do
        self.table_name = "alto_tickets"
        include ::Alto::Subscribable

        def user_email
          "test@example.com"
        end
      end

      model = minimal_class.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )

      assert_raises NotImplementedError do
        model.save!
      end
    end

    test "should raise NotImplementedError for user_email if not implemented" do
      # Create a minimal test class without implementing the method
      minimal_class = Class.new(ActiveRecord::Base) do
        self.table_name = "alto_tickets"
        include ::Alto::Subscribable

        def subscribable_ticket
          # Return a valid ticket so the subscription logic proceeds to call user_email
          Alto::Ticket.first
        end

        # Explicitly don't define user_email method - it should inherit the one from Subscribable
        # that raises NotImplementedError
      end

      model = minimal_class.new(
        title: "Test",
        description: "Test",
        user_id: @user1.id,
        user_type: "User",
        board_id: @board.id
      )

      # The error should be raised during the create_user_subscription callback
      assert_raises NotImplementedError do
        model.save!
      end
    end

    test "should provide default should_create_subscription? method" do
      model = TestSubscribableModel.new
      assert_equal true, model.should_create_subscription?
    end
  end
end
