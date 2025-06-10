#!/usr/bin/env ruby

# Alto Install Generator Test Script
# Run this to test the install generator

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
      f.puts 'gem "alto", path: "../feedback_board"'
    end

    run_command("bundle install")

    # Add routes
    routes_content = File.read("config/routes.rb")
    unless routes_content.include?("Alto::Engine")
      File.open("config/routes.rb", "w") do |f|
        f.puts routes_content.gsub(/end\s*\z/, '  mount Alto::Engine => "/feedback"\nend')
      end
    end

    puts "📋 Generated files to check:"
          puts "  • config/initializers/alto.rb"
    if say_yes_to_defaults
      puts "  • db/migrate/*_create_alto_defaults.rb"
    end
    puts ""

    puts "🎯 Next steps:"
    puts "  1. cd #{app_name}"
          puts "  2. rails generate alto:install"
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

puts "🚀 Alto Install Generator Test"
puts "=" * 50

# Clean environment
FileUtils.rm_rf("./test_app") if Dir.exist?("./test_app")

# Create new Rails app
puts "📦 Creating new Rails app..."
system("rails new test_app --skip-turbo --skip-hotwire --skip-spring")

Dir.chdir("test_app") do
  # Add gem to Gemfile
  gemfile_content = File.read("Gemfile")
  File.write("Gemfile", gemfile_content + "\ngem 'alto', path: '../'\n")

  # Bundle install
  puts "📦 Installing gems..."
  system("bundle install")

  # Add route if not exists
  routes_file = "config/routes.rb"
  routes_content = File.read(routes_file)

  unless routes_content.include?("Alto::Engine")
    puts "🛤️  Adding route..."
    File.write(routes_file, routes_content.gsub(/end\s*\z/, '  mount Alto::Engine => "/feedback"\nend'))
  end

  # Generate User model (common requirement)
  puts "👤 Creating User model..."
  system("rails generate model User email:string")

  # Run install generator
  puts "⚙️  Running Alto installer..."
  system("rails generate alto:install")

  puts "✅ Test install complete! Check test_app directory"
  puts "💡 To test manually:"
  puts "   cd test_app"
  puts "   rails server"
  puts "   Visit: http://localhost:3000/feedback"
end

puts "🎉 Alto Install Test Complete!"
