# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"

# Set up migration paths for engine testing
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)

# Load Rails test framework
require "rails/test_help"

# Run migrations for test environment
begin
  ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
rescue => e
  puts "Migration warning (may be expected): #{e.message}"
end

# Suppress pending migration warnings for in-memory database
# ActiveRecord::Migration.maintain_test_schema!

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Configure proper test isolation strategy
class ActiveSupport::TestCase
  # Use transactional rollback for test isolation instead of manual cleanup
  self.use_transactional_tests = true
end

class ActionDispatch::IntegrationTest
  # Use transactional rollback for integration tests too
  self.use_transactional_tests = true
end
