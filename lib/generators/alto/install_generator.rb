module Alto
  module Generators
    class InstallGenerator < Rails::Generators::Base
                  desc <<~DESC
        Install Alto - complete setup in one command!

        This automatically handles everything:
        • Asks about database preference (same or separate database)
        • Installs database migrations
        • Runs migrations
        • Creates configuration file
        • Sets up default boards
        • Ready to use immediately!

        Examples:
          rails generate alto:install                              # Interactive install (recommended)
          rails generate alto:install --separate-database          # Use separate database
          rails generate alto:install --no-separate-database       # Use same database (default)
          rails generate alto:install --skip-migrations            # Skip database setup
      DESC

      class_option :skip_migrations, type: :boolean, default: false, desc: "Skip running database migrations"
      class_option :separate_database, type: :boolean, default: nil, desc: "Use separate database for Alto (prompted if not specified)"

      def install_alto
        say "Installing Alto...", :green
        say ""

        # Ask about separate database preference (unless already specified or skipping migrations)
        @use_separate_database = determine_database_preference unless options[:skip_migrations]

        # Setup separate database configuration if requested
        setup_database_configuration if @use_separate_database && !options[:skip_migrations]

        # Install and run migrations using Rails conventions
        install_migrations unless options[:skip_migrations]

        # Create initializer (if needed)
        check_and_create_initializer

        # Ask about default boards (if none exist)
        check_and_ask_about_default_boards

        # Final status and next steps
        show_final_status

        say "Alto installation complete! 🎉", :green
      end

      private

      def determine_database_preference
        # If option was explicitly set via command line, use it
        return options[:separate_database] unless options[:separate_database].nil?

        # Otherwise, ask the user
        say ""
        say "═" * 70, :cyan
        say "🗄️  DATABASE CONFIGURATION", :cyan
        say "═" * 70, :cyan
        say ""
        say "Alto can store its data in either:", :blue
        say ""
        say "  1️⃣  Same database as your app (recommended)", :green
        say "     ✅ Simple setup, zero deployment complexity", :green
        say "     ✅ Works with any hosting platform", :green
        say "     ✅ Standard Rails engine pattern", :green
        say ""
        say "  2️⃣  Separate database (advanced)", :yellow
        say "     ⚠️  Requires additional database provisioning", :yellow
        say "     ⚠️  Cannot join queries across databases", :yellow
        say "     ⚠️  More complex backup/deployment", :yellow
        say "     ✅ Complete data isolation", :yellow
        say "     ✅ Independent scaling/backups", :yellow
        say ""

        response = ask("Use separate database for Alto? (y/N):", :cyan, limited_to: ["y", "Y", "n", "N", ""])

        use_separate = ["y", "Y"].include?(response)

        say ""
        if use_separate
          say "✅ Will configure separate database for Alto", :green
        else
          say "✅ Will use same database as your app (standard pattern)", :green
        end
        say ""

        use_separate
      end

      def setup_database_configuration
        say "🗄️  Setting up separate database for Alto...", :blue

        # Check if database.yml already has alto configuration
        database_yml_path = Rails.root.join("config", "database.yml")
        database_content = File.read(database_yml_path) if File.exist?(database_yml_path)

        if database_content && database_content.include?("alto:")
          say "✅ Alto database configuration already exists in database.yml", :green
        else
          say "📝 Adding Alto database configuration to database.yml...", :blue
          add_alto_database_config(database_yml_path, database_content)
          say "✅ Added Alto database configuration", :green
        end

        # Create storage directory if it doesn't exist
        storage_dir = Rails.root.join("storage")
        FileUtils.mkdir_p(storage_dir) unless Dir.exist?(storage_dir)

        say ""
      end

      def add_alto_database_config(database_yml_path, existing_content)
        # Backup existing database.yml
        backup_path = "#{database_yml_path}.alto_backup_#{Time.current.to_i}"
        File.write(backup_path, existing_content) if existing_content

        # Detect primary database configuration to mirror
        primary_config = detect_primary_database_config(existing_content)

        # Add Alto database configuration using same adapter as primary
        alto_config = generate_alto_config(primary_config)

        # Append to existing database.yml
        File.write(database_yml_path, existing_content + alto_config)

        say "💾 Created backup: #{backup_path}", :yellow if existing_content
      end

      def detect_primary_database_config(database_content)
        # Parse the database.yml to find primary configuration
        begin
          parsed = YAML.load_file(Rails.root.join("config", "database.yml"))
          primary_dev = parsed.dig("development", "primary") || parsed["development"]

          {
            adapter: primary_dev["adapter"],
            host: primary_dev["host"],
            port: primary_dev["port"],
            username: primary_dev["username"],
            password: primary_dev["password"],
            encoding: primary_dev["encoding"]
          }.compact
        rescue => e
          say "⚠️  Could not parse database.yml, using defaults: #{e.message}", :yellow
          { adapter: "postgresql" }  # Safe default
        end
      end

      def generate_alto_config(primary_config)
        adapter = primary_config[:adapter] || "postgresql"

        case adapter
        when "postgresql"
          generate_postgresql_alto_config(primary_config)
        when "mysql2"
          generate_mysql_alto_config(primary_config)
        when "sqlite3"
          generate_sqlite_alto_config
        else
          generate_postgresql_alto_config(primary_config)  # Default to PostgreSQL
        end
      end

      def generate_postgresql_alto_config(primary_config)
        <<~YAML

          # Alto Feedback Engine - Separate Database
          # Uses same adapter as your primary database
          alto:
            development:
              <<: *default
              database: alto_development
              #{"host: #{primary_config[:host]}" if primary_config[:host]}
              #{"port: #{primary_config[:port]}" if primary_config[:port]}
              #{"username: #{primary_config[:username]}" if primary_config[:username]}
              #{"password: #{primary_config[:password]}" if primary_config[:password]}

            test:
              <<: *default
              database: alto_test
              #{"host: #{primary_config[:host]}" if primary_config[:host]}
              #{"port: #{primary_config[:port]}" if primary_config[:port]}
              #{"username: #{primary_config[:username]}" if primary_config[:username]}
              #{"password: #{primary_config[:password]}" if primary_config[:password]}

            production:
              <<: *default
              database: alto_production
              #{"host: #{primary_config[:host]}" if primary_config[:host]}
              #{"port: #{primary_config[:port]}" if primary_config[:port]}
              username: <%= ENV["ALTO_DATABASE_USERNAME"] || "#{primary_config[:username]}" %>
              password: <%= ENV["ALTO_DATABASE_PASSWORD"] %>
        YAML
      end

      def generate_mysql_alto_config(primary_config)
        <<~YAML

          # Alto Feedback Engine - Separate Database
          # Uses same adapter as your primary database
          alto:
            development:
              <<: *default
              database: alto_development
              #{"host: #{primary_config[:host]}" if primary_config[:host]}
              #{"port: #{primary_config[:port]}" if primary_config[:port]}
              #{"username: #{primary_config[:username]}" if primary_config[:username]}
              #{"password: #{primary_config[:password]}" if primary_config[:password]}

            test:
              <<: *default
              database: alto_test
              #{"host: #{primary_config[:host]}" if primary_config[:host]}
              #{"port: #{primary_config[:port]}" if primary_config[:port]}
              #{"username: #{primary_config[:username]}" if primary_config[:username]}
              #{"password: #{primary_config[:password]}" if primary_config[:password]}

            production:
              <<: *default
              database: alto_production
              #{"host: #{primary_config[:host]}" if primary_config[:host]}
              #{"port: #{primary_config[:port]}" if primary_config[:port]}
              username: <%= ENV["ALTO_DATABASE_USERNAME"] || "#{primary_config[:username]}" %>
              password: <%= ENV["ALTO_DATABASE_PASSWORD"] %>
        YAML
      end

      def generate_sqlite_alto_config
        <<~YAML

          # Alto Feedback Engine - Separate Database
          # Uses SQLite like your primary database
          alto:
            development:
              <<: *default
              database: storage/alto_development.sqlite3

            test:
              <<: *default
              database: storage/alto_test.sqlite3

            production:
              <<: *default
              database: storage/alto_production.sqlite3
        YAML
      end

                              def install_migrations
        say "📦 Installing database migrations...", :blue

        begin
          # Copy ONLY Alto migrations (avoid ActionMailbox/ActionText)
          copy_alto_migrations

          # Detect multi-database setup
          multi_db_info = detect_multi_database_setup

          if multi_db_info[:is_multi_db]
            handle_multi_database_migration(multi_db_info)
          else
            handle_single_database_migration
          end

        rescue => e
          say "❌ Migration failed: #{e.message}", :red
          say ""
          show_migration_troubleshooting_help
          say ""
          raise "Installation halted due to migration failure"
        end

        say ""
      end

      def detect_multi_database_setup
        multi_db_info = {
          is_multi_db: false,
          databases: [],
          primary_database: nil,
          available_tasks: []
        }

        begin
          # Check database configuration
          if defined?(ActiveRecord::Base.configurations)
            config = ActiveRecord::Base.configurations.configurations

            # Count unique database names (excluding test environments)
            database_names = config.select { |c| !c.name.include?("test") }.map(&:database).uniq

            if database_names.length > 1
              multi_db_info[:is_multi_db] = true
              multi_db_info[:databases] = database_names
            end
          end

          # Check available rake tasks for database-specific migrations
          available_tasks = `rake -T 2>/dev/null | grep "db:migrate:" | grep -v "db:migrate:status"`.strip.split("\n")
          multi_db_info[:available_tasks] = available_tasks.map { |task| task.split[1] }.compact

          # Look for primary database task
          if multi_db_info[:available_tasks].any? { |task| task.include?("primary") }
            multi_db_info[:primary_database] = "primary"
            multi_db_info[:is_multi_db] = true
          end

          # Alternative check: look for multiple db:migrate: tasks
          if multi_db_info[:available_tasks].length > 1
            multi_db_info[:is_multi_db] = true
          end

        rescue => e
          Rails.logger.debug "Alto: Could not detect multi-database setup: #{e.message}"
        end

        multi_db_info
      end

      def handle_multi_database_migration(multi_db_info)
        say ""
        say "🔍 Multi-Database Setup Detected!", :yellow
        say "   Available databases: #{multi_db_info[:databases].join(', ')}" if multi_db_info[:databases].any?
        say "   Available migration tasks: #{multi_db_info[:available_tasks].join(', ')}" if multi_db_info[:available_tasks].any?
        say ""

        # Check if tables already exist before migrating
        if alto_tables_exist?
          say "✅ Alto tables already exist - skipping migration", :green
          return
        end

        say "⚡ Running database migrations for multi-database setup...", :blue

        # Try to run migration on primary database first
        if multi_db_info[:primary_database] == "primary"
          begin
            say "   → Running migration on primary database...", :blue
            rake "db:migrate:primary"
            say "✅ Database setup complete on primary database!", :green
            return
          rescue => e
            say "⚠️  Primary database migration failed: #{e.message}", :yellow
          end
        end

        # Fallback to trying available database-specific tasks
        migration_success = false
        multi_db_info[:available_tasks].each do |task|
          next if task == "db:migrate" # Skip generic task

          begin
            say "   → Trying #{task}...", :blue
            rake task
            say "✅ Database setup complete using #{task}!", :green
            migration_success = true
            break
          rescue => e
            say "⚠️  #{task} failed: #{e.message}", :yellow
          end
        end

        unless migration_success
          say ""
          say "❌ Automatic migration failed for multi-database setup", :red
          say ""
          say "💡 Manual Setup Required:", :yellow
          say "Please run ONE of these commands manually:", :blue
          say ""

          if multi_db_info[:primary_database] == "primary"
            say "   # Most common for multi-database Rails apps:", :green
            say "   rails db:migrate:primary", :cyan
            say ""
          end

          multi_db_info[:available_tasks].each do |task|
            next if task == "db:migrate"
            say "   # Alternative:", :blue
            say "   rake #{task}", :cyan
          end

          say ""
          say "Then re-run the generator:", :blue
          say "   rails generate alto:install --skip-migrations", :cyan
          say ""

          raise "Multi-database migration requires manual intervention"
        end
      end

      def handle_single_database_migration
        if @use_separate_database
          say "⚡ Running database migrations on Alto database...", :blue

          # Check if tables already exist before migrating
          if alto_tables_exist?
            say "✅ Alto tables already exist - skipping migration", :green
          else
            # Create the Alto database first
            begin
              rake "db:create:alto"
              say "✅ Created Alto database", :green
            rescue => e
              say "⚠️  Database creation: #{e.message}", :yellow
            end

            # Run migrations on the Alto database
            rake "db:migrate:alto"
            say "✅ Database setup complete on Alto database!", :green
          end
        else
          say "⚡ Running database migrations on primary database...", :blue

          # Check if tables already exist before migrating
          if alto_tables_exist?
            say "✅ Alto tables already exist - skipping migration", :green
          else
            # Run migrations on the primary database
            rake "db:migrate"
            say "✅ Database setup complete on primary database!", :green
          end
        end
      end

      def show_migration_troubleshooting_help
        say "💡 Troubleshooting Tips:", :yellow
        say ""
        say "For Alto separate database setup, try:", :blue
        say "   rails db:create:alto", :cyan
        say "   rails db:migrate:alto", :cyan
        say ""
        say "For multi-database setups, also try:", :blue
        say "   rails db:migrate:primary", :cyan
        say "   # or", :blue
        say "   rake railties:install:migrations SOURCE=alto", :cyan
        say "   rails db:migrate:alto", :cyan
        say ""
        say "Then re-run with --skip-migrations:", :blue
        say "   rails generate alto:install --skip-migrations", :cyan
      end

      def check_and_create_initializer
        initializer_path = "config/initializers/alto.rb"

        if File.exist?(initializer_path)
          say "✅ Initializer already exists at #{initializer_path}", :green
        else
          say "📝 Creating initializer...", :blue
          create_initializer
          say "✅ Created #{initializer_path}", :green
        end
        say ""
      end

      def check_and_ask_about_default_boards
        say "🎯 Setting up default boards...", :blue

        begin
          board_count = ::Alto::Board.count
          if board_count == 0
            create_default_boards
          else
            say "✅ Found #{board_count} existing board(s) - skipping default board creation", :green
          end
        rescue => e
          say "⚠️  Could not check existing boards: #{e.message}", :yellow
          say "You can create boards manually in the admin area later.", :blue
        end
        say ""
      end

      def create_default_boards
        begin
          say "🚀 Default Board Setup", :cyan
          say "Creating default Feature Requests board...", :yellow
          say ""

          # Create everything in a transaction for safety
          ActiveRecord::Base.transaction do
            create_feature_requests_board
          end

          say "✅ Default board created successfully!", :green
          say ""
          say "🎯 Available board:", :cyan
          say "  • /feedback/boards/feature-requests (Feature Requests → 'New request')", :blue

        rescue => e
          say "❌ Failed to create board: #{e.message}", :red
          say "💡 You can create boards manually in the admin area later", :yellow
        end
      end

      def create_feature_requests_board
        # Create Feature Requests status set
        status_set = ::Alto::StatusSet.create!(
          name: "Feature Requests",
          description: "Product ideas and improvements. Statuses: open → planned → in_progress → complete → closed",
          is_default: true
        )

        # Create statuses for Feature Requests
        [
          [ "Open", "green", 0, "open" ],
          [ "Planned", "blue", 1, "planned" ],
          [ "In Progress", "yellow", 2, "in_progress" ],
          [ "Complete", "purple", 3, "complete" ],
          [ "Closed", "gray", 4, "closed" ]
        ].each do |name, color, position, slug|
          status_set.statuses.create!(
            name: name,
            color: color,
            position: position,
            slug: slug
          )
        end

        # Create the single default board
        ::Alto::Board.create!(
          name: "Feature Requests",
          slug: "feature-requests",
          description: "Product ideas and improvements. Statuses: open → planned → in_progress → complete → closed",
          item_label_singular: "request",
          status_set: status_set
        )
      end

      def copy_alto_migrations
        # Get the source migrations directory from the engine
        source_migrations = File.join(::Alto::Engine.root, "db", "migrate")
        destination_migrations = Rails.root.join("db", "migrate")

        # Ensure destination directory exists
        FileUtils.mkdir_p(destination_migrations)

        # Get all Alto migration files
        migration_files = Dir.glob(File.join(source_migrations, "*.rb"))

        if migration_files.empty?
          say "⚠️  No Alto migrations found", :yellow
          return
        end

        copied_count = 0
        migration_files.each do |source_file|
          filename = File.basename(source_file)

          # Generate a new timestamp for this migration
          timestamp = Time.current.utc.strftime("%Y%m%d%H%M%S").to_i
          timestamp += copied_count # Ensure unique timestamps

          # Create new filename with current timestamp + alto suffix
          new_filename = "#{timestamp}_#{filename.gsub(/^\d+_/, '')}"
          new_filename = new_filename.gsub(".rb", ".alto.rb") unless new_filename.include?("alto")

          destination_file = File.join(destination_migrations, new_filename)

          # Skip if migration already exists (check by content similarity)
          if migration_already_exists?(source_file, destination_migrations)
            say "   exists    #{new_filename}", :green
          else
            FileUtils.cp(source_file, destination_file)
            say "   copied    #{new_filename}", :green
            copied_count += 1
          end
        end

        if copied_count > 0
          say "📦 Copied #{copied_count} Alto migration(s)", :green
        else
          say "📦 All Alto migrations already present", :green
        end
      end

      def migration_already_exists?(source_file, destination_dir)
        source_content = File.read(source_file)

        # Look for existing migrations with similar class names
        class_name_match = source_content.match(/class\s+(\w+)\s+</)
        return false unless class_name_match

        class_name = class_name_match[1]

        # Check if any existing migration has the same class name
        Dir.glob(File.join(destination_dir, "*alto*.rb")).any? do |existing_file|
          existing_content = File.read(existing_file)
          existing_content.include?("class #{class_name}")
        end
      end

      def show_final_status
        say "📋 Installation Summary:", :cyan
        say ""

        # Detect multi-database setup for final status
        multi_db_info = detect_multi_database_setup

        # Check routes
        routes_content = File.read("config/routes.rb") rescue ""
        if routes_content.include?("Alto::Engine")
          say "✅ Routes: Alto engine is mounted", :green
        else
          say "⚠️  Routes: Add 'mount Alto::Engine => \"/feedback\"' to config/routes.rb (or whatever path you want)", :yellow
        end

        # Check initializer
        if File.exist?("config/initializers/alto.rb")
          say "✅ Config: Initializer exists at config/initializers/alto.rb", :green
        else
          say "❌ Config: No initializer found", :red
        end

        # Check database with multi-database awareness
        begin
          connection = ::Alto::ApplicationRecord.connection
          if connection.table_exists?("alto_boards")
            say "✅ Database: All Alto tables ready in separate database", :green
          else
            say "⚠️  Database: Tables may not be ready", :yellow

            # Provide specific guidance for multi-database setups
            if multi_db_info[:is_multi_db]
              say ""
              say "🔍 Multi-Database Setup Detected - Tables Missing!", :yellow
              say "   This might be why tables aren't ready. Try:", :blue

              if multi_db_info[:primary_database] == "primary"
                say "   rails db:migrate:primary", :cyan
              end

              multi_db_info[:available_tasks].each do |task|
                next if task == "db:migrate"
                say "   rake #{task}", :cyan
              end

              say ""
              say "   Then re-run: rails generate alto:install --skip-migrations", :blue
            end
          end
        rescue
          say "⚠️  Database: Could not verify (may still be setting up)", :yellow

          # Show multi-database troubleshooting
          if multi_db_info[:is_multi_db]
            say ""
            say "🔍 Multi-Database Setup Detected!", :yellow
            say "   If tables are missing, try these migration commands:", :blue

            if multi_db_info[:primary_database] == "primary"
              say "   rails db:migrate:primary", :cyan
            end

            multi_db_info[:available_tasks].each do |task|
              next if task == "db:migrate"
              say "   rake #{task}", :cyan
            end
          end
        end

        # Check boards
        begin
          board_count = ::Alto::Board.count
          if board_count > 0
            say "✅ Boards: #{board_count} board(s) available", :green
          else
            say "⚠️  Boards: No boards found - create some in admin area", :yellow
          end
        rescue => e
          say "⚠️  Boards: Could not check (database may still be initializing)", :yellow

          # Additional context for multi-database setups
          if multi_db_info[:is_multi_db] && e.message.include?("does not exist")
            say "   → This looks like a multi-database migration issue", :blue
            say "   → Try the migration commands above first", :blue
          end
        end

        say ""
        say "🚀 Next Steps:", :yellow
        say "1. Visit the path you configured in config/routes.rb to see Alto"
        say "2. Customize permissions in config/initializers/alto.rb"
        say "3. Implement callback methods in your ApplicationController for notifications"
        say ""

        # Show multi-database specific guidance
        if multi_db_info[:is_multi_db]
          say "📚 Multi-Database App Detected:", :cyan
          say "   If you encounter database issues, remember to use database-specific commands:", :blue
          say "   • For migrations: rails db:migrate:primary (or your database name)", :blue
          say "   • For console: rails console (should work normally)", :blue
          say "   • For seeds: rails db:seed:primary (if needed)", :blue
          say ""
        end

        say "💡 To uninstall: rails generate alto:uninstall", :blue
        say ""
      end

      def alto_tables_exist?
        begin
          # Check if Alto tables exist in the Alto database
          ::Alto::ApplicationRecord.connection.table_exists?("alto_boards") &&
          ::Alto::ApplicationRecord.connection.table_exists?("alto_tickets") &&
          ::Alto::ApplicationRecord.connection.table_exists?("alto_status_sets")
        rescue
          false
        end
      end

      def create_initializer
        separate_db_section = if @use_separate_database
          <<~SEPARATE_DB
            # ===== SEPARATE DATABASE CONFIGURATION =====
                # Alto is configured to use a separate database (configured in database.yml as 'alto:')
                # This keeps Alto's feedback data completely separate from your main app data.
                config.use_separate_database = true

                # Commands for Alto database management:
                #   rails db:create:alto                    # Create Alto database
                #   rails db:migrate:alto                   # Run Alto migrations
                #   rails db:rollback:alto                  # Rollback Alto migrations
                #   rails db:reset:alto                     # Reset Alto database
                #
                # Alto uses the same database adapter as your primary database.
                # The database names will be: alto_development, alto_test, alto_production
                #
                # Alto tables (all prefixed with 'alto_'):
                #   alto_boards, alto_tickets, alto_comments, alto_upvotes,
                #   alto_subscriptions, alto_status_sets, alto_statuses,
                #   alto_settings, alto_fields, alto_tags, alto_taggings
          SEPARATE_DB
        else
          <<~SAME_DB
            # ===== DATABASE CONFIGURATION =====
                # Alto uses the same database as your main application (standard Rails engine pattern)
                # All Alto tables are prefixed with 'alto_' to avoid conflicts.
                config.use_separate_database = false

                # If you want to switch to a separate database later:
                # 1. Set config.use_separate_database = true
                # 2. Add alto: section to config/database.yml
                # 3. Run: rails db:create:alto && rails db:migrate:alto
                # 4. Restart your app
          SAME_DB
        end

        initializer_content = <<~RUBY
          # Alto Configuration
          Alto.configure do |config|
            #{separate_db_section.strip.gsub(/^/, '  ')}

            # User model configuration
            config.user_model = "User"

            # Current user configuration (optional - smart defaults usually work)
            # Uncomment and customize only if you have non-standard authentication:
            #
            # For apps using Current.user pattern:
            # config.current_user { Current.user }
            #
            # For session-based authentication:
            # config.current_user { User.find_by(id: session[:user_id]) }
            #
            # For custom authentication:
            # config.current_user { your_authentication_method }

            # User display name (customize for your user model)
            # config.user_display_name do |user_id|
            #   user = User.find_by(id: user_id)
            #   user&.name || user&.email || "User #\#{user_id}"
            # end

            # User profile avatar URL (optional - for showing user avatars)
            # config.user_profile_avatar_url do |user_id|
            #   user = User.find_by(id: user_id)
            #   user&.avatar&.url  # Adjust for your avatar method (e.g., Gravatar, Active Storage, etc.)
            # end

            # Permission methods (customize for your authentication system)

            # Who can access Alto at all?
            config.permission :can_access_alto? do
              user_signed_in?  # Devise helper, adjust for your auth system
            end

            # Who can submit new tickets?
            config.permission :can_submit_tickets? do
              current_user.present?
            end

            # Who can comment on tickets?
            config.permission :can_comment? do
              current_user.present?
            end

            # Who can vote on tickets and comments?
            config.permission :can_vote? do
              current_user.present?
            end

            # Who can edit any ticket? (Usually admins only)
            config.permission :can_edit_tickets? do
              current_user&.admin?
            end

            # Who can access the admin area?
            config.permission :can_access_admin? do
              current_user&.admin?
            end

            # Who can manage boards? (Create, edit, delete boards)
            config.permission :can_manage_boards? do
              current_user&.admin?
            end

            # Who can access specific boards? (board-level access control)
            # config.permission :can_access_board? do |board|
            #   case board.slug
            #   when 'internal'
            #     current_user&.staff?
            #   else
            #     current_user.present?
            #   end
            # end

            # Board configuration
            config.allow_board_deletion_with_tickets = false

            # Image uploads (requires ActiveStorage setup)
            # config.image_uploads_enabled = true
          end
        RUBY

        create_file "config/initializers/alto.rb", initializer_content
      end
    end
  end
end
