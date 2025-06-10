module FeedbackBoard
  module Generators
    class UninstallGenerator < Rails::Generators::Base
      desc <<~DESC
        Uninstall FeedbackBoard - complete removal in one command!

        This safely removes:
        • Configuration files
        • Database tables (optional)
        • Provides cleanup instructions
        • Maintains data safety with confirmations

        Examples:
          rails generate feedback_board:uninstall    # Interactive uninstall with prompts
      DESC

      def uninstall_feedback_board
        say "🗑️  Uninstalling FeedbackBoard...", :red
        say ""

        # Warning about data loss
        show_data_warning

        # Remove initializer
        remove_initializer

        # Ask about database cleanup
        ask_about_database_cleanup

        # Provide route removal instructions
        provide_route_instructions

        # Final instructions
        provide_final_instructions

        say "FeedbackBoard uninstallation complete! 👋", :green
      end

      private

      def show_data_warning
        say "⚠️  WARNING: Uninstalling FeedbackBoard", :red
        say ""
        say "This will remove FeedbackBoard configuration and optionally all data.", :yellow
        say "This action cannot be easily undone!", :red
        say ""

        unless yes?("Are you sure you want to continue? (y/n)", :red)
          say "Uninstall cancelled. FeedbackBoard remains installed.", :green
          exit
        end
        say ""
      end

      def remove_initializer
        initializer_path = "config/initializers/feedback_board.rb"

        if File.exist?(initializer_path)
          say "🗑️  Removing initializer...", :yellow
          remove_file initializer_path
          say "✅ Removed #{initializer_path}", :green
        else
          say "ℹ️  No initializer found at #{initializer_path}", :blue
        end
        say ""
      end

      def ask_about_database_cleanup
        say "🗄️  Database Cleanup", :cyan
        say "FeedbackBoard has created the following tables in your database:", :yellow
        say ""
        say "  • feedback_board_status_sets", :blue
        say "  • feedback_board_statuses", :blue
        say "  • feedback_board_boards", :blue
        say "  • feedback_board_tickets", :blue
        say "  • feedback_board_comments", :blue
        say "  • feedback_board_upvotes", :blue
        say "  • feedback_board_settings", :blue
        say ""
        say "⚠️  WARNING: This will permanently delete ALL feedback data!", :red
        say "This includes all tickets, comments, upvotes, and configuration.", :red
        say ""

        if yes?("Create database cleanup migration? (y/n)", :yellow)
          create_database_cleanup_migration
        else
          say "Skipping database cleanup. Tables will remain in your database.", :yellow
          say "You can manually remove them later if needed.", :blue
        end
        say ""
      end

      def create_database_cleanup_migration
        say "📝 Creating database cleanup migration...", :blue

        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        migration_file = "db/migrate/#{timestamp}_remove_feedback_board_tables.rb"

        migration_content = <<~RUBY
          class RemoveFeedbackBoardTables < ActiveRecord::Migration[7.0]
            def up
              # Disable foreign key checks for safe removal
              connection = ActiveRecord::Base.connection

              say "🗑️  Removing FeedbackBoard tables and indexes..."

              # Remove tables in dependency order (children first)
              remove_table_safely(:feedback_board_upvotes)
              remove_table_safely(:feedback_board_comments)
              remove_table_safely(:feedback_board_tickets)
              remove_table_safely(:feedback_board_statuses)
              remove_table_safely(:feedback_board_boards)
              remove_table_safely(:feedback_board_status_sets)
              remove_table_safely(:feedback_board_settings)

              say "✅ FeedbackBoard database tables removed successfully"
            end

            def down
              # This migration is irreversible
              # To restore, you would need to:
              # 1. Reinstall the FeedbackBoard gem
              # 2. Run: rails generate feedback_board:install
              # 3. Restore data from backup (if available)

              raise ActiveRecord::IrreversibleMigration,
                    "Cannot restore FeedbackBoard tables automatically. " \\
                    "You must reinstall the gem and restore data from backup."
            end

            private

            def remove_table_safely(table_name)
              if table_exists?(table_name)
                say "  • Removing \#{table_name}..."

                # Remove foreign key constraints first
                foreign_keys(table_name).each do |fk|
                  remove_foreign_key table_name, name: fk.name
                end

                # Remove the table (indexes are automatically removed)
                drop_table table_name
              else
                say "  • \#{table_name} not found (skipping)"
              end
            rescue => e
              say "  ⚠️  Could not remove \#{table_name}: \#{e.message}", :yellow
            end
          end
        RUBY

        create_file migration_file, migration_content

        say "✅ Created migration: #{migration_file}", :green
        say ""
        say "⚡ Running database cleanup migration...", :blue

        begin
          rake "db:migrate"
          say "✅ Database cleanup completed successfully!", :green
        rescue => e
          say "❌ Migration failed: #{e.message}", :red
          say "You may need to run 'rails db:migrate' manually.", :yellow
        end
        say ""
      end

      def provide_route_instructions
        say "🛤️  Route Removal", :cyan
        say "Please manually remove the FeedbackBoard route from your routes file:", :yellow
        say ""
        say "  📁 config/routes.rb", :blue
        say "  Remove this line:", :yellow
        say "    mount FeedbackBoard::Engine => \"/feedback\"", :red
        say ""

        if yes?("Open routes file for editing? (y/n)", :green)
          system("${EDITOR:-nano} config/routes.rb")
        end
        say ""
      end

      def provide_final_instructions
        say "📋 Final Steps", :cyan
        say ""
        say "1. Remove the gem from your Gemfile:", :yellow
        say "   gem 'feedback_board'  # ← Remove this line", :red
        say ""
        say "2. Run bundle install:", :yellow
        say "   bundle install", :blue
        say ""
        say "3. (Optional) Remove any custom FeedbackBoard views/overrides:", :yellow
        say "   app/views/feedback_board/", :blue
        say "   app/assets/stylesheets/feedback_board_custom.*", :blue
        say ""
        say "4. (Optional) Remove callback methods from ApplicationController:", :yellow
        say "   ticket_created, comment_created, upvote_created, etc.", :blue
        say ""
        say "💡 Pro tip: Keep a backup of your data before final removal!", :green
        say ""
      end
    end
  end
end
