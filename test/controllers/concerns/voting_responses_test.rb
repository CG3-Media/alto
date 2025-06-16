require 'test_helper'

class VotingResponsesTest < ActiveSupport::TestCase
  # Create a test class that includes the concern
  class TestController
    include VotingResponses

    attr_accessor :request, :response, :upvotable, :board

    def initialize
      @flash = {}
    end

        # Mock the respond_to method
    def respond_to(&block)
      format = MockFormat.new
      block.call(format)
    end

    # Mock the redirect_back method
    def redirect_back(options = {})
      @last_redirect_options = options
      @flash[:alert] = options[:alert] if options[:alert]
    end

    attr_reader :last_redirect_options

    # Mock flash
    def flash
      @flash ||= {}
    end

    # Mock alto engine routes
    def alto
      self
    end

    def board_tickets_path(board)
      "/alto/boards/#{board.slug}/tickets"
    end

    def board_ticket_path(board, ticket)
      "/alto/boards/#{board.slug}/tickets/#{ticket.id}"
    end

    def alto_home_path
      "/alto"
    end
  end

    class MockFormat
    def initialize
      @render_calls = []
    end

    def html(&block)
      # Default format is HTML, so we'll execute the block
      block.call if block_given?
    end

    def json(&block)
      # For JSON format, execute the block and capture the render call
      if block_given?
        block.call
      end
    end
  end

  def setup
    @controller = TestController.new
    @board = alto_boards(:bugs)
    @ticket = alto_tickets(:test_ticket)
    @controller.board = @board
  end

  test "fallback_path returns board tickets path for ticket upvotable" do
    @controller.upvotable = @ticket

    path = @controller.send(:fallback_path)
    expected_path = "/alto/boards/#{@board.slug}/tickets"

    assert_equal expected_path, path
  end

    test "fallback_path returns board ticket path for comment upvotable" do
    # Create a mock comment object
    ticket = @ticket  # Capture in local variable for closure
    comment = Object.new
    comment.define_singleton_method(:is_a?) { |klass| klass.name == 'Alto::Comment' }
    comment.define_singleton_method(:ticket) { ticket }

    @controller.upvotable = comment

    path = @controller.send(:fallback_path)
    expected_path = "/alto/boards/#{@board.slug}/tickets/#{@ticket.id}"

    assert_equal expected_path, path
  end

  test "fallback_path returns alto home path for unknown upvotable" do
    @controller.upvotable = Object.new

    path = @controller.send(:fallback_path)
    expected_path = "/alto"

    assert_equal expected_path, path
  end

  test "respond_with_vote_success calls redirect_back for HTML format" do
    @controller.upvotable = @ticket
    @ticket.define_singleton_method(:upvotes_count) { 5 }

    # Override respond_to to test HTML format
    @controller.define_singleton_method(:respond_to) do |&block|
      format = Object.new
      format.define_singleton_method(:html) { |&html_block| html_block.call }
      format.define_singleton_method(:json) { |&json_block| }
      block.call(format)
    end

    # Test that redirect_back is called
    redirect_called = false
    redirect_options = nil
    @controller.define_singleton_method(:redirect_back) do |options|
      redirect_called = true
      redirect_options = options
    end

    @controller.send(:respond_with_vote_success, @ticket, true)
    assert redirect_called, "redirect_back should have been called"
    assert_equal "/alto/boards/#{@board.slug}/tickets", redirect_options[:fallback_location]
  end

  test "respond_with_vote_error calls redirect_back with alert for HTML format" do
    error_message = "Something went wrong"

    # Override respond_to to test HTML format
    @controller.define_singleton_method(:respond_to) do |&block|
      format = Object.new
      format.define_singleton_method(:html) { |&html_block| html_block.call }
      format.define_singleton_method(:json) { |&json_block| }
      block.call(format)
    end

        # Test that redirect_back is called with alert
    redirect_called = false
    redirect_options = nil
    @controller.define_singleton_method(:redirect_back) do |options|
      redirect_called = true
      redirect_options = options
    end

    @controller.send(:respond_with_vote_error, error_message)
    assert redirect_called, "redirect_back with alert should have been called"
    assert_equal error_message, redirect_options[:alert]
  end

  test "respond_with_permission_denied calls redirect_back with permission alert for HTML format" do
    # Override respond_to to test HTML format
    @controller.define_singleton_method(:respond_to) do |&block|
      format = Object.new
      format.define_singleton_method(:html) { |&html_block| html_block.call }
      format.define_singleton_method(:json) { |&json_block| }
      block.call(format)
    end

        # Test that redirect_back is called with permission alert
    redirect_called = false
    redirect_options = nil
    @controller.define_singleton_method(:redirect_back) do |options|
      redirect_called = true
      redirect_options = options
    end

    @controller.send(:respond_with_permission_denied)
    assert redirect_called, "redirect_back with permission alert should have been called"
    assert_equal "You do not have permission to vote", redirect_options[:alert]
  end
end
