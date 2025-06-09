module FeedbackBoard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install FeedbackBoard"

      def install_feedback_board
        say "Installing FeedbackBoard...", :green
        say ""

        # Check and handle database setup
        check_database_setup

        # Create initializer (if needed)
        check_and_create_initializer

        # Ask about default boards (if none exist)
        check_and_ask_about_default_boards

        # Final status and next steps
        show_final_status

        say "FeedbackBoard installation complete! 🎉", :green
      end

      private

      def check_database_setup
        say "🔍 Checking database setup...", :blue

        missing_tables = check_missing_tables

        if missing_tables.empty?
          say "✅ All database tables exist", :green
        else
          say "📋 Missing tables: #{missing_tables.join(', ')}", :yellow

          if yes?("Create missing database tables? (y/n)", :green)
            say "🛠️  Creating database tables...", :blue

            begin
              ::FeedbackBoard::DatabaseSetup.force_setup!
              say "✅ Database tables created successfully!", :green
            rescue => e
              say "❌ Database setup failed: #{e.message}", :red
              say "💡 Try running: rails feedback_board:setup", :yellow
            end
          else
            say "⏭️  Skipping database setup. Run 'rails feedback_board:setup' later if needed.", :yellow
          end
        end
        say ""
      end

      def check_missing_tables
        required_tables = [
          'feedback_board_status_sets',
          'feedback_board_statuses',
          'feedback_board_boards',
          'feedback_board_tickets',
          'feedback_board_comments',
          'feedback_board_upvotes',
          'feedback_board_settings'
        ]

        connection = ActiveRecord::Base.connection
        required_tables.reject { |table| connection.table_exists?(table) }
      rescue => e
        Rails.logger.debug "Could not check tables: #{e.message}"
        []
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
        # Check if any boards exist
        boards_exist = false
        boards_count = 0

        begin
          boards_count = ::FeedbackBoard::Board.count
          boards_exist = boards_count > 0
        rescue => e
          say "⚠️  Could not check existing boards (database may not be ready)", :yellow
          return
        end

        if boards_exist
          say "✅ Found #{boards_count} existing board(s) - skipping default board creation", :green
          say ""
          return
        end

        say "🚀 Default Board Setup", :cyan
        say "No boards found. Let's create some example boards with custom item labels!", :yellow
        say ""
        say "💡 Each board can have custom labels (e.g., 'post', 'bug', 'issue', 'request')", :blue
        say ""

        create_default_boards
        say ""
      end

      def create_default_boards
        begin
          # Check if status sets already exist
          status_sets_exist = ::FeedbackBoard::StatusSet.exists?

          boards_to_create = []

          # Ask about Feature Requests board
          if yes?("🛠  Create 'Feature Requests' board? (items called 'requests') (y/n)", :green)
            boards_to_create << :features
          end

          # Ask about Bug Reports board
          if yes?("🐞 Create 'Bug Reports' board? (items called 'bugs') (y/n)", :green)
            boards_to_create << :bugs
          end

          # Ask about General Discussion board
          if yes?("💬 Create 'General Discussion' board? (items called 'posts') (y/n)", :green)
            boards_to_create << :discussion
          end

          if boards_to_create.empty?
            say "⏭️  No boards selected. Create custom boards in the admin area later!", :yellow
            return
          end

          say "📋 Creating #{boards_to_create.length} board(s)...", :blue

          # Create everything in a transaction for safety
          ActiveRecord::Base.transaction do
            create_status_sets_and_boards(boards_to_create, status_sets_exist)
          end

          say "✅ #{boards_to_create.length} board(s) created successfully!", :green
          say ""
          say "🎯 Available boards:", :cyan

          if boards_to_create.include?(:features)
            say "  • /feedback/boards/features (Feature Requests → 'New Request')", :blue
          end
          if boards_to_create.include?(:bugs)
            say "  • /feedback/boards/bugs (Bug Reports → 'New Bug')", :blue
          end
          if boards_to_create.include?(:discussion)
            say "  • /feedback/boards/discussion (General Discussion → 'New Post')", :blue
          end

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
        missing_tables = check_missing_tables
        if missing_tables.empty?
          say "✅ Database: All tables exist", :green
        else
          say "⚠️  Database: Missing tables - run 'rails feedback_board:setup'", :yellow
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
          say "⚠️  Boards: Could not check (database may not be ready)", :yellow
        end

        say ""
        say "🚀 Next Steps:", :yellow
        say "1. Visit /feedback in your app to see the feedback board"
        say "2. Customize permissions in config/initializers/feedback_board.rb"
        say "3. Implement callback methods in your ApplicationController for notifications"
        say ""
      end

      def create_initializer
        initializer_content = <<~RUBY
          # FeedbackBoard Configuration
          FeedbackBoard.configure do |config|
            # User model configuration
            config.user_model = "User"

            # User display name (customize for your user model)
            # config.user_display_name_method = proc do |user_id|
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
