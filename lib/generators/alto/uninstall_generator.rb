module Alto
  module Generators
    class UninstallGenerator < Rails::Generators::Base
      desc <<~DESC
        Uninstall Alto - complete removal in one command!

        This safely removes:
        • Configuration files
        • Database tables (optional)
        • Provides cleanup instructions
        • Maintains data safety with confirmations

        Examples:
          rails generate alto:uninstall    # Interactive uninstall with prompts
      DESC

      def uninstall_alto
        say "🗑️  Uninstalling Alto...", :red
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

        say "Alto uninstallation complete! 👋", :green
      end

      private

      def show_data_warning
        say "⚠️  WARNING: Uninstalling Alto", :red
        say ""
        say "This will remove Alto configuration and optionally all data.", :yellow
        say "This action cannot be easily undone!", :red
        say ""

        unless yes?("Are you sure you want to continue? (y/n)", :red)
          say "Uninstall cancelled. Alto remains installed.", :green
          exit
        end
        say ""
      end

      def remove_initializer
        initializer_path = "config/initializers/alto.rb"

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
        say "Alto has created the following tables in your database:", :yellow
        say ""
        say "  • alto_status_sets", :blue
        say "  • alto_statuses", :blue
        say "  • alto_boards", :blue
        say "  • alto_tickets", :blue
        say "  • alto_comments", :blue
        say "  • alto_upvotes", :blue
        say "  • alto_subscriptions", :blue
        say "  • alto_taggings", :blue
        say "  • alto_tags", :blue
        say "  • alto_fields", :blue
        say "  • alto_settings", :blue
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
        migration_file = "db/migrate/#{timestamp}_remove_alto_tables.rb"

        migration_content = <<~RUBY
          class RemoveAltoTables < ActiveRecord::Migration[7.0]
            def up
              # Disable foreign key checks for safe removal
              connection = ActiveRecord::Base.connection

              say "🗑️  Removing Alto tables and indexes..."

              # Remove all Alto tables (CASCADE handles dependencies automatically)
              [
                :alto_upvotes,
                :alto_comments,
                :alto_subscriptions,
                :alto_taggings,
                :alto_tickets,
                :alto_tags,
                :alto_fields,
                :alto_statuses,
                :alto_boards,
                :alto_status_sets,
                :alto_settings
              ].each { |table| remove_table_safely(table) }

              say "✅ Alto database tables removed successfully"
            end

            def down
              # This migration is irreversible
              # To restore, you would need to:
              # 1. Reinstall the Alto gem
              # 2. Run: rails generate alto:install
              # 3. Restore data from backup (if available)

              raise ActiveRecord::IrreversibleMigration,
                    "Cannot restore Alto tables automatically. " \\
                    "You must reinstall the gem and restore data from backup."
            end

            private

            def remove_table_safely(table_name)
              return unless table_exists?(table_name)

              say "  • Removing \#{table_name}..."

              # Use database-specific CASCADE for bulletproof removal
              if connection.adapter_name.downcase.include?('postgresql')
                # PostgreSQL: Use CASCADE to automatically drop dependent objects
                execute "DROP TABLE IF EXISTS \#{table_name} CASCADE"
              elsif connection.adapter_name.downcase.include?('mysql')
                # MySQL: Disable foreign key checks temporarily
                execute "SET FOREIGN_KEY_CHECKS=0"
                drop_table table_name, if_exists: true
                execute "SET FOREIGN_KEY_CHECKS=1"
              else
                # SQLite and others: Drop normally (SQLite handles foreign keys differently)
                drop_table table_name, if_exists: true
              end

              say "    ✓ Removed", :green
            rescue => e
              say "  ⚠️  Could not remove \#{table_name}: \#{e.message}", :yellow
              # Continue anyway - don't let one table failure stop the whole uninstall
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
        say "Please manually remove the Alto route from your routes file:", :yellow
        say ""
        say "  📁 config/routes.rb", :blue
        say "  Remove this line:", :yellow
        say "    mount Alto::Engine => \"/your-path\"", :red
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
                  say "   gem 'alto'  # ← Remove this line", :red
        say ""
        say "2. Run bundle install:", :yellow
        say "   bundle install", :blue
        say ""
        say "3. (Optional) Remove any custom Alto views/overrides:", :yellow
                  say "   app/views/alto/", :blue
        say "   app/assets/stylesheets/alto_custom.*", :blue
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
