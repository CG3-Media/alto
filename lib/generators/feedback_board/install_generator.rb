module FeedbackBoard
  module Generators
    class InstallGenerator < Rails::Generators::Base
                  desc <<~DESC
        Install FeedbackBoard - complete setup in one command!

        This automatically handles everything:
        • Installs database migrations
        • Runs migrations
        • Creates configuration file
        • Sets up default boards
        • Ready to use immediately!

        Examples:
          rails generate feedback_board:install              # Complete install
          rails generate feedback_board:install --skip-migrations  # Skip database setup
      DESC

      class_option :skip_migrations, type: :boolean, default: false, desc: "Skip running database migrations"

      def install_feedback_board
        say "Installing FeedbackBoard...", :green
        say ""

        # Install and run migrations using Rails conventions
        install_migrations unless options[:skip_migrations]

        # Create initializer (if needed)
        check_and_create_initializer

        # Ask about default boards (if none exist)
        check_and_ask_about_default_boards

        # Final status and next steps
        show_final_status

        say "FeedbackBoard installation complete! 🎉", :green
      end

      private

                              def install_migrations
        say "📦 Installing database migrations...", :blue

        begin
          # Copy ONLY FeedbackBoard migrations (avoid ActionMailbox/ActionText)
          copy_feedback_board_migrations

          say "⚡ Running database migrations...", :blue

          # Check if tables already exist before migrating
          if feedback_board_tables_exist?
            say "✅ FeedbackBoard tables already exist - skipping migration", :green
          else
            # Run migrations (Rails handles what's already been run)
            rake "db:migrate"
            say "✅ Database setup complete!", :green
          end
        rescue => e
          say "❌ Migration failed: #{e.message}", :red
          say ""
          say "💡 Try running these commands manually:", :yellow
          say "   rake railties:install:migrations SOURCE=feedback_board", :blue
          say "   rake db:migrate", :blue
          say ""
          raise "Installation halted due to migration failure"
        end

        say ""
      end

      def check_and_create_initializer
        initializer_path = "config/initializers/feedback_board.rb"

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
          board_count = ::FeedbackBoard::Board.count
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
          say "Creating example boards with different workflows...", :yellow
          say ""

          # Check if status sets already exist
          status_sets_exist = ::FeedbackBoard::StatusSet.exists?

          # Create all default boards for better initial experience
          boards_to_create = [:features, :bugs, :discussion]

          say "📋 Creating #{boards_to_create.length} default board(s)...", :blue

          # Create everything in a transaction for safety
          ActiveRecord::Base.transaction do
            create_status_sets_and_boards(boards_to_create, status_sets_exist)
          end

          say "✅ #{boards_to_create.length} board(s) created successfully!", :green
          say ""
          say "🎯 Available boards:", :cyan
          say "  • /feedback/boards/features (Feature Requests → 'New Request')", :blue
          say "  • /feedback/boards/bugs (Bug Reports → 'New Bug')", :blue
          say "  • /feedback/boards/discussion (General Discussion → 'New Post')", :blue

        rescue => e
          say "❌ Failed to create boards: #{e.message}", :red
          say "💡 You can create boards manually in the admin area later", :yellow
        end
      end

      def create_status_sets_and_boards(boards_to_create, status_sets_exist)
        status_sets = {}

        # Only create status sets if they don't exist and if we need them
        unless status_sets_exist
          # Create Feature Requests status set if needed
          if boards_to_create.include?(:features)
            status_sets[:features] = ::FeedbackBoard::StatusSet.create!(
              name: 'Feature Requests',
              description: 'Product ideas and improvements workflow',
              is_default: true
            )

            # Create statuses for Feature Requests
            [
              ['Open', 'green', 0, 'open'],
              ['Planned', 'blue', 1, 'planned'],
              ['In Progress', 'yellow', 2, 'in_progress'],
              ['Complete', 'purple', 3, 'complete'],
              ['Closed', 'gray', 4, 'closed']
            ].each do |name, color, position, slug|
              status_sets[:features].statuses.create!(
                name: name,
                color: color,
                position: position,
                slug: slug
              )
            end
          end

          # Create Bug Reports status set if needed
          if boards_to_create.include?(:bugs)
            status_sets[:bugs] = ::FeedbackBoard::StatusSet.create!(
              name: 'Bug Reports',
              description: 'Bug triage and resolution workflow'
            )

            # Create statuses for Bug Reports
            [
              ['Open', 'green', 0, 'open'],
              ['Acknowledged', 'blue', 1, 'acknowledged'],
              ['In Progress', 'yellow', 2, 'in_progress'],
              ['Fixed', 'purple', 3, 'fixed'],
              ['Won\'t Fix', 'red', 4, 'wont_fix']
            ].each do |name, color, position, slug|
              status_sets[:bugs].statuses.create!(
                name: name,
                color: color,
                position: position,
                slug: slug
              )
            end
          end

          # Create General Discussion status set if needed
          if boards_to_create.include?(:discussion)
            status_sets[:discussion] = ::FeedbackBoard::StatusSet.create!(
              name: 'General Discussion',
              description: 'Simple conversation flow'
            )

            # Create statuses for General Discussion
            [
              ['Open', 'green', 0, 'open'],
              ['Resolved', 'blue', 1, 'resolved'],
              ['Closed', 'gray', 2, 'closed']
            ].each do |name, color, position, slug|
              status_sets[:discussion].statuses.create!(
                name: name,
                color: color,
                position: position,
                slug: slug
              )
            end
          end
        else
          # Use existing status sets
          if boards_to_create.include?(:features)
            status_sets[:features] = ::FeedbackBoard::StatusSet.find_by(name: 'Feature Requests') || ::FeedbackBoard::StatusSet.first
          end
          if boards_to_create.include?(:bugs)
            status_sets[:bugs] = ::FeedbackBoard::StatusSet.find_by(name: 'Bug Reports') || ::FeedbackBoard::StatusSet.first
          end
          if boards_to_create.include?(:discussion)
            status_sets[:discussion] = ::FeedbackBoard::StatusSet.find_by(name: 'General Discussion') || ::FeedbackBoard::StatusSet.first
          end
        end

        # Create only the selected boards with custom item labels
        if boards_to_create.include?(:features)
          ::FeedbackBoard::Board.create!(
            name: '🛠 Feature Requests',
            slug: 'features',
            description: 'Product ideas and improvements. Statuses: open → planned → in_progress → complete → closed',
            item_label_singular: 'request',
            status_set: status_sets[:features]
          )
        end

        if boards_to_create.include?(:bugs)
          ::FeedbackBoard::Board.create!(
            name: '🐞 Bug Reports',
            slug: 'bugs',
            description: 'Bug triage and resolution. Statuses: open → acknowledged → in_progress → fixed → won\'t_fix',
            item_label_singular: 'bug',
            status_set: status_sets[:bugs]
          )
        end

        if boards_to_create.include?(:discussion)
          ::FeedbackBoard::Board.create!(
            name: '💬 General Discussion',
            slug: 'discussion',
            description: 'Simple conversations. Statuses: open → resolved → closed',
            item_label_singular: 'post',
            status_set: status_sets[:discussion]
          )
        end
      end

      def copy_feedback_board_migrations
        # Get the source migrations directory from the engine
        source_migrations = File.join(::FeedbackBoard::Engine.root, "db", "migrate")
        destination_migrations = Rails.root.join("db", "migrate")

        # Ensure destination directory exists
        FileUtils.mkdir_p(destination_migrations)

        # Get all FeedbackBoard migration files
        migration_files = Dir.glob(File.join(source_migrations, "*.rb"))

        if migration_files.empty?
          say "⚠️  No FeedbackBoard migrations found", :yellow
          return
        end

        copied_count = 0
        migration_files.each do |source_file|
          filename = File.basename(source_file)

          # Generate a new timestamp for this migration
          timestamp = Time.current.utc.strftime("%Y%m%d%H%M%S").to_i
          timestamp += copied_count # Ensure unique timestamps

          # Create new filename with current timestamp + feedback_board suffix
          new_filename = "#{timestamp}_#{filename.gsub(/^\d+_/, '')}"
          new_filename = new_filename.gsub('.rb', '.feedback_board.rb') unless new_filename.include?('feedback_board')

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
          say "📦 Copied #{copied_count} FeedbackBoard migration(s)", :green
        else
          say "📦 All FeedbackBoard migrations already present", :green
        end
      end

      def migration_already_exists?(source_file, destination_dir)
        source_content = File.read(source_file)

        # Look for existing migrations with similar class names
        class_name_match = source_content.match(/class\s+(\w+)\s+</)
        return false unless class_name_match

        class_name = class_name_match[1]

        # Check if any existing migration has the same class name
        Dir.glob(File.join(destination_dir, "*feedback_board*.rb")).any? do |existing_file|
          existing_content = File.read(existing_file)
          existing_content.include?("class #{class_name}")
        end
      end

      def show_final_status
        say "📋 Installation Summary:", :cyan
        say ""

        # Check routes
        routes_content = File.read("config/routes.rb") rescue ""
        if routes_content.include?("FeedbackBoard::Engine")
          say "✅ Routes: FeedbackBoard engine is mounted", :green
        else
          say "⚠️  Routes: Add 'mount FeedbackBoard::Engine => \"/feedback\"' to config/routes.rb", :yellow
        end

        # Check initializer
        if File.exist?("config/initializers/feedback_board.rb")
          say "✅ Config: Initializer exists at config/initializers/feedback_board.rb", :green
        else
          say "❌ Config: No initializer found", :red
        end

        # Check database
        begin
          connection = ActiveRecord::Base.connection
          if connection.table_exists?('feedback_board_boards')
            say "✅ Database: All tables ready", :green
          else
            say "⚠️  Database: Tables may not be ready", :yellow
          end
        rescue
          say "⚠️  Database: Could not verify (may still be setting up)", :yellow
        end

        # Check boards
        begin
          board_count = ::FeedbackBoard::Board.count
          if board_count > 0
            say "✅ Boards: #{board_count} board(s) available", :green
          else
            say "⚠️  Boards: No boards found - create some in admin area", :yellow
          end
        rescue
          say "⚠️  Boards: Could not check (database may still be initializing)", :yellow
        end

        say ""
                say "🚀 Next Steps:", :yellow
        say "1. Visit /feedback in your app to see the feedback board"
        say "2. Customize permissions in config/initializers/feedback_board.rb"
        say "3. Implement callback methods in your ApplicationController for notifications"
        say ""
        say "💡 To uninstall: rails generate feedback_board:uninstall", :blue
        say ""
      end

      def feedback_board_tables_exist?
        begin
          ActiveRecord::Base.connection.table_exists?('feedback_board_boards') &&
          ActiveRecord::Base.connection.table_exists?('feedback_board_tickets') &&
          ActiveRecord::Base.connection.table_exists?('feedback_board_status_sets')
        rescue
          false
        end
      end

      def create_initializer
        initializer_content = <<~RUBY
          # FeedbackBoard Configuration
          FeedbackBoard.configure do |config|
            # User model configuration
            config.user_model = "User"

            # User display name (customize for your user model)
            # config.user_display_name do |user_id|
            #   user = User.find_by(id: user_id)
            #   user&.name || user&.email || "User #\#{user_id}"
            # end

            # Permission methods (customize for your authentication system)

            # Who can access the feedback board at all?
            config.permission :can_access_feedback_board? do
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
          end
        RUBY

        create_file "config/initializers/feedback_board.rb", initializer_content
      end
    end
  end
end
