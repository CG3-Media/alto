module FeedbackBoard
  class DatabaseSetup
    def self.setup_if_needed
      return unless should_setup?

      Rails.logger.info "[FeedbackBoard] Setting up database schema..."

      install_and_run_migrations

      Rails.logger.info "[FeedbackBoard] Database setup complete!"
    end

    # Force database setup regardless of existing tables
    def self.force_setup!
      Rails.logger.info "[FeedbackBoard] Force setting up database schema..."

      install_and_run_migrations

      Rails.logger.info "[FeedbackBoard] Database setup complete!"
    end

    private

    def self.should_setup?
      # Only setup if we're connected to a database and tables don't exist
      ActiveRecord::Base.connection.present? && !all_tables_exist?
    rescue => e
      Rails.logger.warn "[FeedbackBoard] Could not check database: #{e.message}"
      false
    end

    def self.all_tables_exist?
      required_tables = [
        'feedback_board_status_sets',
        'feedback_board_statuses',
        'feedback_board_boards',
        'feedback_board_tickets',
        'feedback_board_comments',
        'feedback_board_upvotes',
        'feedback_board_settings',
        'feedback_board_subscriptions'
      ]

      connection = ActiveRecord::Base.connection
      required_tables.all? { |table| connection.table_exists?(table) }
    end

        # Legacy method name for backward compatibility
    def self.tables_exist?
      all_tables_exist?
    end

                def self.install_and_run_migrations
      Rails.logger.info "[FeedbackBoard] Installing and running migrations..."

      # Copy migrations to host app (like `rails feedback_board:install:migrations`)
      copy_migrations_to_host_app

      # Run migrations
      Rails.logger.info "[FeedbackBoard] Running database migrations..."
      system("rails db:migrate")

      Rails.logger.info "[FeedbackBoard] Migrations complete"
    end

    def self.copy_migrations_to_host_app
      # Use Rails' built-in engine migration installer
      require 'rails/generators'
      require 'rails/generators/migration'

      # This copies all missing migrations from the engine to the host app
      Rails.application.railties.engines.each do |engine|
        if engine.class.name == "FeedbackBoard::Engine"
          migrations_path = File.join(engine.root, 'db', 'migrate')
          if Dir.exist?(migrations_path)
            Rails.logger.info "[FeedbackBoard] Copying migrations from engine..."
            FileUtils.cp_r "#{migrations_path}/.", Rails.root.join('db', 'migrate')
          end
        end
      end
    rescue => e
      Rails.logger.warn "[FeedbackBoard] Could not copy migrations: #{e.message}"
      # Continue anyway - migrations might already be copied
    end

    # Legacy method - kept for compatibility
    def self.create_tables
      Rails.logger.info "[FeedbackBoard] Running migrations (legacy create_tables called)"
      install_and_run_migrations
    end

  end
end
