#!/usr/bin/env ruby

# FeedbackBoard Install Generator Test Script
# Run this from the feedback_board gem directory

require 'fileutils'

def run_command(cmd)
  puts "🔄 Running: #{cmd}"
  system(cmd)
  puts ""
end

def test_scenario(scenario_name, say_yes_to_defaults = false)
  puts "🧪 Testing Scenario: #{scenario_name}"
  puts "=" * 50

  app_name = say_yes_to_defaults ? "feedback_test_with_defaults" : "feedback_test_no_defaults"

  # Clean up any existing test app
  FileUtils.rm_rf(app_name) if Dir.exist?(app_name)

  # Create new Rails app
  run_command("rails new #{app_name} --skip-git")

  Dir.chdir(app_name) do
    # Add gem to Gemfile
    File.open("Gemfile", "a") do |f|
      f.puts 'gem "feedback_board", path: "../feedback_board"'
    end

    run_command("bundle install")

    # Add routes
    routes_content = File.read("config/routes.rb")
    unless routes_content.include?("FeedbackBoard::Engine")
      File.open("config/routes.rb", "w") do |f|
        f.puts routes_content.gsub(/end\s*\z/, '  mount FeedbackBoard::Engine => "/feedback"\nend')
      end
    end

    puts "📋 Generated files to check:"
    puts "  • config/initializers/feedback_board.rb"
    if say_yes_to_defaults
      puts "  • db/migrate/*_create_feedback_board_defaults.rb"
    end
    puts ""

    puts "🎯 Next steps:"
    puts "  1. cd #{app_name}"
    puts "  2. rails generate feedback_board:install"
    if say_yes_to_defaults
      puts "     (Say YES when prompted)"
      puts "  3. rails server"
      puts "  4. Visit http://localhost:3000/feedback"
    else
      puts "     (Say NO when prompted)"
      puts "  3. Create custom boards in admin area"
    end
    puts ""
  end

  puts "✅ #{scenario_name} setup complete!"
  puts ""
end

puts "🚀 FeedbackBoard Install Generator Test"
puts "=" * 40
puts ""

test_scenario("No Default Boards", false)
test_scenario("With Default Boards", true)

puts "🏁 Both test scenarios are ready!"
puts ""
puts "💡 Tips:"
puts "  • Test both scenarios to ensure the interactive prompts work"
puts "  • Check that default boards have correct statuses and descriptions"
puts "  • Verify URLs work: /feedback/boards/features, /feedback/boards/bugs, /feedback/boards/discussion"
puts "  • Test admin area: /feedback/admin"
