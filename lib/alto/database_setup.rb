module Alto
  class DatabaseSetup
    def self.setup_if_needed
      return unless should_setup?

      Rails.logger.info "[Alto] Setting up database schema..."

      install_and_run_migrations

      Rails.logger.info "[Alto] Database setup complete!"
    end

    # Force database setup regardless of existing tables
    def self.force_setup!
      Rails.logger.info "[Alto] Force setting up database schema..."

      install_and_run_migrations

      Rails.logger.info "[Alto] Database setup complete!"
    end

    private

    def self.should_setup?
      # Only setup if we're connected to a database and tables don't exist
      ActiveRecord::Base.connection.present? && !all_tables_exist?
    rescue => e
      Rails.logger.warn "[Alto] Could not check database: #{e.message}"
      false
    end

    def self.all_tables_exist?
      required_tables = [
        'alto_status_sets',
        'alto_statuses',
        'alto_boards',
        'alto_tickets',
        'alto_comments',
        'alto_upvotes',
        'alto_settings',
        'alto_subscriptions'
      ]

      connection = ActiveRecord::Base.connection
      required_tables.all? { |table| connection.table_exists?(table) }
    end

        # Legacy method name for backward compatibility
    def self.tables_exist?
      all_tables_exist?
    end

                def self.install_and_run_migrations
      Rails.logger.info "[Alto] Installing and running migrations..."

      # Copy migrations to host app (like `rails alto:install:migrations`)
      copy_migrations_to_host_app

      # Run migrations
      Rails.logger.info "[Alto] Running database migrations..."
      system("rails db:migrate")

      Rails.logger.info "[Alto] Migrations complete"
    end

    def self.copy_migrations_to_host_app
      # Use Rails' built-in engine migration installer
      require 'rails/generators'
      require 'rails/generators/migration'

      # This copies all missing migrations from the engine to the host app
      Rails.application.railties.engines.each do |engine|
        if engine.class.name == "Alto::Engine"
          migrations_path = File.join(engine.root, 'db', 'migrate')
          if Dir.exist?(migrations_path)
            Rails.logger.info "[Alto] Copying migrations from engine..."
            FileUtils.cp_r "#{migrations_path}/.", Rails.root.join('db', 'migrate')
          end
        end
      end
    rescue => e
      Rails.logger.warn "[Alto] Could not copy migrations: #{e.message}"
      # Continue anyway - migrations might already be copied
    end

    # Legacy method - kept for compatibility
    def self.create_tables
      Rails.logger.info "[Alto] Running migrations (legacy create_tables called)"
      install_and_run_migrations
    end

  end
end
