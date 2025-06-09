namespace :feedback_board do
  desc "Setup FeedbackBoard database tables"
  task setup: :environment do
    puts "🚀 Setting up FeedbackBoard database tables..."

    begin
      FeedbackBoard::DatabaseSetup.force_setup!
      puts "✅ FeedbackBoard database setup completed successfully!"
      puts ""
      puts "📋 Created tables:"
      puts "  • feedback_board_status_sets"
      puts "  • feedback_board_statuses"
      puts "  • feedback_board_boards"
      puts "  • feedback_board_tickets"
      puts "  • feedback_board_comments"
      puts "  • feedback_board_upvotes"
      puts "  • feedback_board_settings"
      puts ""
      puts "🎉 You can now visit /feedback in your application!"
    rescue => e
      puts "❌ Failed to setup FeedbackBoard database:"
      puts "   #{e.message}"
      puts ""
      puts "💡 Troubleshooting tips:"
      puts "  1. Make sure your database is running"
      puts "  2. Ensure your Rails app can connect to the database"
      puts "  3. Check that ActiveRecord is properly configured"
      exit 1
    end
  end

  desc "Check FeedbackBoard database status"
  task status: :environment do
    puts "🔍 Checking FeedbackBoard database status..."
    puts ""

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

    puts "📋 Table Status:"
    missing_tables = []

    required_tables.each do |table|
      exists = connection.table_exists?(table)
      status = exists ? "✅ EXISTS" : "❌ MISSING"
      puts "  #{table.ljust(30)} #{status}"
      missing_tables << table unless exists
    end

    puts ""

    if missing_tables.empty?
      puts "🎉 All FeedbackBoard tables exist!"
    else
      puts "⚠️  Missing #{missing_tables.length} table(s):"
      missing_tables.each { |table| puts "   • #{table}" }
      puts ""
      puts "🔧 To fix this, run:"
      puts "   rails feedback_board:setup"
    end
  end

  desc "Reset FeedbackBoard database (WARNING: destroys all data)"
  task reset: :environment do
    puts "⚠️  WARNING: This will destroy ALL FeedbackBoard data!"
    print "Are you sure? Type 'yes' to continue: "

    input = STDIN.gets.chomp
    unless input.downcase == 'yes'
      puts "❌ Reset cancelled."
      exit
    end

    puts "🗑️  Dropping FeedbackBoard tables..."

    connection = ActiveRecord::Base.connection
    tables_to_drop = [
      'feedback_board_upvotes',
      'feedback_board_comments',
      'feedback_board_tickets',
      'feedback_board_statuses',
      'feedback_board_status_sets',
      'feedback_board_boards',
      'feedback_board_settings'
    ]

    tables_to_drop.each do |table|
      if connection.table_exists?(table)
        connection.drop_table(table)
        puts "  ✅ Dropped #{table}"
      end
    end

    puts ""
    puts "🚀 Recreating tables..."
    FeedbackBoard::DatabaseSetup.force_setup!
    puts "✅ FeedbackBoard database reset completed!"
  end
end
