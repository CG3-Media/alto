require 'test_helper'

module FeedbackBoard
  class TicketsControllerTest < ActionController::TestCase
    class MockUser
      attr_accessor :id, :email, :admin

      def initialize(id: 1, email: 'test@example.com', admin: false)
        @id = id
        @email = email
        @admin = admin
      end

      def admin?
        @admin
      end
    end

    def setup
      @controller = TicketsController.new
      @user = MockUser.new

      # Create a board for testing
      @board = Board.create!(name: 'Test Board', slug: 'test-board', description: 'Test board')

      # Mock current_user
      @controller.define_singleton_method(:current_user) { @user }
    end

    test "controller inherits permission methods from ApplicationController" do
      # Critical test: ensure TicketsController has the can_access_board? method
      assert_respond_to @controller, :can_access_board?
      assert_respond_to @controller, :can_edit_tickets?
      assert_respond_to @controller, :can_submit_tickets?
      assert_respond_to @controller, :can_comment?
      assert_respond_to @controller, :can_vote?
    end

    test "can_access_board? method works on TicketsController instance" do
      # This should not raise NoMethodError
      assert_nothing_raised do
        result = @controller.send(:can_access_board?, @board)
        assert_equal true, result, "TicketsController should inherit can_access_board? method"
      end
    end

    test "can_access_board? with different board scenarios" do
      # Test with valid board
      result = @controller.send(:can_access_board?, @board)
      assert_equal true, result

      # Test with nil board (should still work)
      result = @controller.send(:can_access_board?, nil)
      assert_equal true, result
    end

    test "check_board_access method exists and can be called" do
      # Mock the set_board method to set @board
      @controller.instance_variable_set(:@board, @board)

      # This should not raise an error
      assert_nothing_raised do
        @controller.send(:check_board_access)
      end
    end

    test "set_board method works with valid slug" do
      # Mock params
      @controller.params = { board_slug: @board.slug }

      assert_nothing_raised do
        @controller.send(:set_board)
        assert_equal @board, @controller.instance_variable_get(:@board)
      end
    end

    test "inheritance chain is complete" do
      # Verify the inheritance chain
      assert_equal ApplicationController, TicketsController.superclass

      # Verify that private methods from ApplicationController are available
      application_controller = ApplicationController.new
      tickets_controller = TicketsController.new

      # Both should respond to the same private methods (when made public)
      application_methods = ApplicationController.private_instance_methods
      tickets_methods = TicketsController.private_instance_methods

      # ApplicationController methods should be in TicketsController
      assert_includes tickets_methods, :can_access_board?
      assert_includes tickets_methods, :delegate_permission
    end

    test "method resolution order includes ApplicationController" do
      # Check that ApplicationController is in the method resolution order
      mro = TicketsController.ancestors
      assert_includes mro, ApplicationController
      assert_includes mro, FeedbackBoard::ApplicationController
    end

    # Test the actual problem scenario
    test "tickets controller can call can_access_board? without error" do
      # This simulates the exact scenario that's failing
      @controller.params = { board_slug: @board.slug }

      # Set up the controller state like a real request
      @controller.send(:set_board)

      # This is what's failing - let's test it directly
      assert_nothing_raised "can_access_board? should be available on TicketsController" do
        @controller.send(:check_board_access)
      end
    end
  end
end
