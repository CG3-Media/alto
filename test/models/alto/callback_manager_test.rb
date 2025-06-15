require "test_helper"

module Alto
  class CallbackManagerTest < ActiveSupport::TestCase
    def setup
      @callback_manager = CallbackManager.new
    end

    def teardown
      # Clean up between tests
      @callback_manager.instance_variable_set(:@main_app_controller, nil)
    end

    test "should call method on main app controller when method exists" do
      # Create a mock controller that responds to our callback
      mock_controller = Class.new do
        def ticket_created(*args)
          @called_with = args
        end

        def called_with
          @called_with
        end
      end

      # Replace the controller instance
      @callback_manager.instance_variable_set(:@main_app_controller, mock_controller.new)

      # Call the callback
      ticket = alto_tickets(:test_ticket)
      board = alto_boards(:bugs)
      user = users(:one)

      @callback_manager.call(:ticket_created, ticket, board, user)

      # Verify the method was called with correct arguments
      controller_instance = @callback_manager.instance_variable_get(:@main_app_controller)
      assert_equal [ticket, board, user], controller_instance.called_with
    end

    test "should not raise error when main app controller doesn't respond to method" do
      # Create a mock controller that doesn't respond to our callback
      mock_controller = Class.new.new
      @callback_manager.instance_variable_set(:@main_app_controller, mock_controller)

      # This should not raise an error
      assert_nothing_raised do
        @callback_manager.call(:non_existent_method, "arg1", "arg2")
      end
    end

    test "should log warning and continue when callback raises error" do
      # Create a mock controller that raises an error
      mock_controller = Class.new do
        def failing_callback(*args)
          raise StandardError, "Callback failed"
        end
      end

      @callback_manager.instance_variable_set(:@main_app_controller, mock_controller.new)

      # Capture log output
      log_output = StringIO.new
      original_logger = Rails.logger
      Rails.logger = Logger.new(log_output)

      # Call should not raise error
      assert_nothing_raised do
        @callback_manager.call(:failing_callback, "test")
      end

      # Should log warning
      log_output.rewind
      log_content = log_output.read
      assert_match(/Alto callback failing_callback failed: Callback failed/, log_content)

      # Restore logger
      Rails.logger = original_logger
    end

    test "should handle private methods correctly" do
      # Create a mock controller with private callback method
      mock_controller = Class.new do
        def initialize
          @private_called = false
        end

        private

        def private_callback(*args)
          @private_called = true
        end

        public

        def private_called?
          @private_called
        end
      end

      controller_instance = mock_controller.new
      @callback_manager.instance_variable_set(:@main_app_controller, controller_instance)

      # Should be able to call private methods
      @callback_manager.call(:private_callback, "test")
      assert controller_instance.private_called?
    end

    test "should cache main app controller instance" do
      # Mock the ApplicationController to avoid NameError
      mock_controller_class = Class.new

      # Temporarily define ApplicationController
      Object.const_set(:ApplicationController, mock_controller_class) unless defined?(::ApplicationController)

      first_call = @callback_manager.send(:main_app_controller)
      second_call = @callback_manager.send(:main_app_controller)

      assert_same first_call, second_call
    ensure
      # Clean up if we defined it
      Object.send(:remove_const, :ApplicationController) if defined?(::ApplicationController) && ::ApplicationController == mock_controller_class
    end

    test "should handle nil arguments gracefully" do
      mock_controller = Class.new do
        def callback_with_nils(*args)
          @args = args
        end

        attr_reader :args
      end

      controller_instance = mock_controller.new
      @callback_manager.instance_variable_set(:@main_app_controller, controller_instance)

      assert_nothing_raised do
        @callback_manager.call(:callback_with_nils, nil, nil, nil)
      end

      assert_equal [nil, nil, nil], controller_instance.args
    end

    test "should handle class method call properly" do
      # Test the class method call delegates to instance
      mock_controller = Class.new do
        def test_callback(*args)
          @class_method_called = args
        end

        attr_reader :class_method_called
      end

      # Create a new callback manager for this test
      test_manager = CallbackManager.new
      test_manager.instance_variable_set(:@main_app_controller, mock_controller.new)

      # Override the class method temporarily for this test
      original_method = CallbackManager.method(:new)
      CallbackManager.define_singleton_method(:new) { test_manager }

      CallbackManager.call(:test_callback, "arg1", "arg2")

      # Restore original method
      CallbackManager.define_singleton_method(:new, original_method)

      controller_instance = test_manager.instance_variable_get(:@main_app_controller)
      assert_equal ["arg1", "arg2"], controller_instance.class_method_called
    end

    test "should handle complex callback arguments" do
      mock_controller = Class.new do
        def complex_callback(ticket, board, user, extra_data)
          @complex_args = { ticket: ticket, board: board, user: user, extra_data: extra_data }
        end

        attr_reader :complex_args
      end

      controller_instance = mock_controller.new
      @callback_manager.instance_variable_set(:@main_app_controller, controller_instance)

      ticket = alto_tickets(:test_ticket)
      board = alto_boards(:bugs)
      user = users(:one)
      extra_data = { status: "created", timestamp: Time.current }

      @callback_manager.call(:complex_callback, ticket, board, user, extra_data)

      expected = { ticket: ticket, board: board, user: user, extra_data: extra_data }
      assert_equal expected, controller_instance.complex_args
    end
  end
end
