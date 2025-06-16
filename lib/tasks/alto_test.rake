namespace :alto do
  namespace :test do
    desc "Prepare Alto test environment"
    task :prepare => :environment do
      Rails.env = "test"

      # Load test environment if not already loaded
      unless Rails.application.initialized?
        require_relative "../../test/dummy/config/environment"
      end

      # Create test database if it doesn't exist
      begin
        ActiveRecord::Base.connection
      rescue ActiveRecord::NoDatabaseError
        puts "Creating test database..."
        ActiveRecord::Tasks::DatabaseTasks.create_current
      end

      # Run migrations
      puts "Running migrations..."
      ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate

      puts "✅ Alto test environment ready!"
    end

    desc "Reset Alto test database"
    task :reset => :environment do
      Rails.env = "test"

      # Drop and recreate test database
      ActiveRecord::Tasks::DatabaseTasks.drop_current
      ActiveRecord::Tasks::DatabaseTasks.create_current

      # Run migrations
      ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate

      puts "✅ Alto test database reset!"
    end
  end
end
