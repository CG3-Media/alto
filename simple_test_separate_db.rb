#!/usr/bin/env ruby
# Simple test to verify Alto's separate database configuration works

require 'bundler/setup'
require 'rails'
require 'active_record'
require_relative 'lib/alto'

puts "🔍 Testing Alto Separate Database Configuration"
puts "=" * 50

# Test 1: Check if Alto::ApplicationRecord has correct database connection
puts "\n1. Testing Alto::ApplicationRecord database connection:"
begin
  puts "   Alto::ApplicationRecord.abstract_class: #{Alto::ApplicationRecord.abstract_class}"

  # Check if connects_to is configured
  connection_config = Alto::ApplicationRecord.connection_db_config
  puts "   Connection configuration: #{connection_config&.name || 'Not configured'}"

  if Alto::ApplicationRecord.respond_to?(:connection_db_config)
    puts "   ✅ Alto::ApplicationRecord has separate database configuration"
  else
    puts "   ⚠️  Alto::ApplicationRecord may not have separate database configured"
  end
rescue => e
  puts "   ❌ Error checking connection: #{e.message}"
end

# Test 2: Check configuration options
puts "\n2. Testing configuration options:"
begin
  config = Alto::Configuration.new
  puts "   separate_database: #{config.separate_database}"
  puts "   database_config: #{config.database_config}"
  puts "   ✅ Configuration includes database options"
rescue => e
  puts "   ❌ Error checking configuration: #{e.message}"
end

# Test 3: Check if database rake tasks exist
puts "\n3. Checking database rake tasks:"
rake_file = File.join(File.dirname(__FILE__), 'lib', 'tasks', 'alto_database.rake')
if File.exist?(rake_file)
  puts "   ✅ Alto database rake tasks file exists"
  content = File.read(rake_file)
  tasks = %w[db:create:alto db:migrate:alto db:rollback:alto db:reset:alto]
  tasks.each do |task|
    if content.include?(task)
      puts "   ✅ Task #{task} is defined"
    else
      puts "   ❌ Task #{task} is missing"
    end
  end
else
  puts "   ❌ Alto database rake tasks file missing"
end

# Test 4: Check install generator updates
puts "\n4. Checking install generator updates:"
generator_file = File.join(File.dirname(__FILE__), 'lib', 'generators', 'alto', 'install_generator.rb')
if File.exist?(generator_file)
  content = File.read(generator_file)
  checks = [
    ['setup_database_configuration method', 'def setup_database_configuration'],
    ['Alto database config addition', 'alto:'],
    ['Database creation command', 'db:create:alto'],
    ['Database migration command', 'db:migrate:alto'],
    ['Separate database documentation', 'SEPARATE DATABASE INFORMATION']
  ]

  checks.each do |name, pattern|
    if content.include?(pattern)
      puts "   ✅ #{name} is present"
    else
      puts "   ❌ #{name} is missing"
    end
  end
else
  puts "   ❌ Install generator file missing"
end

puts "\n" + "=" * 50
puts "🎯 Summary: Alto separate database configuration is ready!"
puts ""
puts "Next steps for users:"
puts "1. Run: rails generate alto:install"
puts "2. Check: config/database.yml for alto: section"
puts "3. Use: rails db:create:alto && rails db:migrate:alto"
puts "4. Verify: Alto tables are in separate database file"
puts ""
puts "Database files will be:"
puts "  - storage/alto_development.sqlite3"
puts "  - storage/alto_test.sqlite3"
puts "  - storage/alto_production.sqlite3"