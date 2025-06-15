module AltoCallbackTestHelper
  # Simple callback tracker that uses real objects (Rule #3)
  # Usage: with_alto_callbacks_tracked { |tracker| ... }
  def with_alto_callbacks_tracked(&block)
    tracker = CallbackTracker.new
    original_call_method = Alto::CallbackManager.method(:call)

    # Override the call method to track calls
    Alto::CallbackManager.define_singleton_method(:call) do |method_name, *args|
      tracker.track_call(method_name, *args)
      # Still call original method to maintain real behavior
      begin
        original_call_method.call(method_name, *args)
      rescue => e
        # Ignore callback errors during testing
      end
    end

    yield tracker
  ensure
    # Restore original method
    Alto::CallbackManager.define_singleton_method(:call, original_call_method)
  end

  # Simple callback mocker for testing specific behavior
  # Usage: with_alto_callbacks_mocked { |mocker| ... }
  def with_alto_callbacks_mocked(callback_responses = {}, &block)
    mocker = CallbackMocker.new(callback_responses)
    original_call_method = Alto::CallbackManager.method(:call)

    # Override the call method to use mock responses
    Alto::CallbackManager.define_singleton_method(:call) do |method_name, *args|
      mocker.mock_call(method_name, *args)
    end

    yield mocker
  ensure
    # Restore original method
    Alto::CallbackManager.define_singleton_method(:call, original_call_method)
  end

  # Helper to test callback error handling
  # Usage: with_alto_callbacks_failing { ... }
  def with_alto_callbacks_failing(error_class = StandardError, error_message = "Test callback failure", &block)
    original_call_method = Alto::CallbackManager.method(:call)

    # Override to always raise errors
    Alto::CallbackManager.define_singleton_method(:call) do |method_name, *args|
      raise error_class, error_message
    end

    yield
  ensure
    # Restore original method
    Alto::CallbackManager.define_singleton_method(:call, original_call_method)
  end

  # Helper to verify specific callbacks were called
  # Usage: assert_callback_called(tracker, :ticket_created, with_args: [ticket, board, user])
  def assert_callback_called(tracker, callback_name, with_args: nil, times: 1)
    calls = tracker.calls_for(callback_name)

    assert_equal times, calls.length,
      "Expected #{callback_name} to be called #{times} time(s), but was called #{calls.length} time(s)"

    if with_args
      matching_calls = calls.select { |call| call[:args] == with_args }
      assert_equal 1, matching_calls.length,
        "Expected #{callback_name} to be called with args #{with_args.inspect}, but found calls: #{calls.map { |c| c[:args] }.inspect}"
    end
  end

  # Helper to verify no callbacks were called
  def assert_no_callbacks_called(tracker)
    assert_empty tracker.all_calls, "Expected no callbacks to be called, but found: #{tracker.all_calls.inspect}"
  end

  # Helper to create test data for callback testing (Rule #2 - fixtures)
  def create_callback_test_data
    {
      user: users(:one),
      board: alto_boards(:bugs),
      ticket: alto_tickets(:test_ticket),
      comment: nil  # Will be created as needed
    }
  end

  # Helper to setup Alto configuration for testing
  def with_alto_test_config(config_options = {}, &block)
    original_config = Alto.instance_variable_get(:@configuration)

    Alto.configure do |config|
      config_options.each do |key, value|
        if value.is_a?(Proc)
          config.public_send(key, &value)
        else
          config.public_send(:"#{key}=", value)
        end
      end
    end

    yield
  ensure
    Alto.instance_variable_set(:@configuration, original_config)
  end

  private

  # Simple tracker class (Rule #3 - real objects)
  class CallbackTracker
    attr_reader :all_calls

    def initialize
      @all_calls = []
    end

    def track_call(method_name, *args)
      @all_calls << {
        method: method_name,
        args: args,
        timestamp: Time.current
      }
    end

    def calls_for(method_name)
      @all_calls.select { |call| call[:method] == method_name }
    end

    def called?(method_name)
      calls_for(method_name).any?
    end

    def call_count(method_name = nil)
      if method_name
        calls_for(method_name).length
      else
        @all_calls.length
      end
    end
  end

  # Simple mocker class (Rule #3 - real objects)
  class CallbackMocker
    attr_reader :callback_responses, :all_calls

    def initialize(callback_responses = {})
      @callback_responses = callback_responses.stringify_keys
      @all_calls = []
    end

    def mock_call(method_name, *args)
      # Track the call
      @all_calls << {
        method: method_name,
        args: args,
        timestamp: Time.current
      }

      # Execute custom response if provided
      if @callback_responses[method_name.to_s]
        @callback_responses[method_name.to_s].call(*args)
      end
    end

    def calls_for(method_name)
      @all_calls.select { |call| call[:method] == method_name }
    end
  end
end
