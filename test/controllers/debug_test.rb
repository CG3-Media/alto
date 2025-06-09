require 'test_helper'

class DebugTest < ActiveSupport::TestCase
  test "debug method inheritance chain" do
    puts "\n=== DEBUGGING METHOD INHERITANCE ==="

    # Check ApplicationController
    app_controller = FeedbackBoard::ApplicationController.new
    puts "ApplicationController methods:"
    puts "  - responds to can_access_board?: #{app_controller.respond_to?(:can_access_board?)}"
    puts "  - responds to can_access_board? (include private): #{app_controller.respond_to?(:can_access_board?, true)}"

    # Check TicketsController
    tickets_controller = FeedbackBoard::TicketsController.new
    puts "\nTicketsController methods:"
    puts "  - responds to can_access_board?: #{tickets_controller.respond_to?(:can_access_board?)}"
    puts "  - responds to can_access_board? (include private): #{tickets_controller.respond_to?(:can_access_board?, true)}"

    # Check inheritance chain
    puts "\nInheritance chain:"
    FeedbackBoard::TicketsController.ancestors.each_with_index do |klass, index|
      puts "  #{index}: #{klass}"
    end

    # Check method resolution
    puts "\nMethod locations:"
    if FeedbackBoard::ApplicationController.private_method_defined?(:can_access_board?)
      puts "  - can_access_board? defined in ApplicationController (private)"
    elsif FeedbackBoard::ApplicationController.method_defined?(:can_access_board?)
      puts "  - can_access_board? defined in ApplicationController (public)"
    else
      puts "  - can_access_board? NOT found in ApplicationController"
    end

    if FeedbackBoard::TicketsController.private_method_defined?(:can_access_board?)
      puts "  - can_access_board? available in TicketsController (private)"
    elsif FeedbackBoard::TicketsController.method_defined?(:can_access_board?)
      puts "  - can_access_board? available in TicketsController (public)"
    else
      puts "  - can_access_board? NOT available in TicketsController"
    end

    # Check all private methods
    puts "\nApplicationController private methods containing 'access':"
    FeedbackBoard::ApplicationController.private_instance_methods.grep(/access/).each do |method|
      puts "  - #{method}"
    end

    puts "\nTicketsController private methods containing 'access':"
    FeedbackBoard::TicketsController.private_instance_methods.grep(/access/).each do |method|
      puts "  - #{method}"
    end

    # Try to actually call the method
    puts "\nTrying to call can_access_board? on TicketsController:"
    begin
      # Mock current_user
      tickets_controller.define_singleton_method(:current_user) {
        Struct.new(:id, :email).new(1, 'test@example.com')
      }

      board = FeedbackBoard::Board.new(name: 'Test', slug: 'test')
      result = tickets_controller.send(:can_access_board?, board)
      puts "  - SUCCESS: #{result}"
    rescue => e
      puts "  - ERROR: #{e.class}: #{e.message}"
      puts "  - Backtrace: #{e.backtrace.first(3).join(' -> ')}"
    end

    assert true, "This test is just for debugging"
  end
end
