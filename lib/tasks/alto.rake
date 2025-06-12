namespace :alto do
  desc "Setup Alto database tables"
  task setup: :environment do
    puts "🚀 Setting up Alto database tables..."

    begin
      # Copy only Alto migrations (avoid ActionMailbox/ActionText)
      puts "📦 Installing Alto migrations only..."
      copy_alto_migrations_only

      puts "⚡ Running migrations..."
      system("rake db:migrate")

      puts "✅ Alto database setup completed successfully!"
      puts ""
      puts "📋 Created tables:"
      puts "  • alto_status_sets"
      puts "  • alto_statuses"
      puts "  • alto_boards"
      puts "  • alto_tickets"
      puts "  • alto_comments"
      puts "  • alto_upvotes"
      puts "  • alto_settings"
      puts "  • alto_subscriptions"
      puts ""
      puts "🎉 You can now visit /feedback in your application!"
    rescue => e
      puts "❌ Failed to setup Alto database:"
      puts "   #{e.message}"
      puts ""
      puts "💡 Troubleshooting tips:"
      puts "  1. Make sure your database is running"
      puts "  2. Ensure your Rails app can connect to the database"
      puts "  3. Check that ActiveRecord is properly configured"
      exit 1
    end
  end

  desc "Check Alto database status"
  task status: :environment do
    puts "🔍 Checking Alto database status..."
    puts ""

    required_tables = [
      "alto_status_sets",
      "alto_statuses",
      "alto_boards",
      "alto_tickets",
      "alto_comments",
      "alto_upvotes",
      "alto_settings",
      "alto_subscriptions"
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
      puts "🎉 All Alto tables exist!"
    else
      puts "⚠️  Missing #{missing_tables.length} table(s):"
      missing_tables.each { |table| puts "   • #{table}" }
      puts ""
      puts "🔧 To fix this, run:"
      puts "   rails alto:setup"
    end
  end

  desc "Reset Alto database (WARNING: destroys all data)"
  task reset: :environment do
    puts "⚠️  WARNING: This will destroy ALL Alto data!"
    print "Are you sure? Type 'yes' to continue: "

    input = STDIN.gets.chomp
    unless input.downcase == "yes"
      puts "❌ Reset cancelled."
      exit
    end

    puts "🗑️  Dropping Alto tables..."

    connection = ActiveRecord::Base.connection
    tables_to_drop = [
      "alto_subscriptions",
      "alto_upvotes",
      "alto_comments",
      "alto_tickets",
      "alto_statuses",
      "alto_status_sets",
      "alto_boards",
      "alto_settings"
    ]

    tables_to_drop.each do |table|
      if connection.table_exists?(table)
        connection.drop_table(table)
        puts "  ✅ Dropped #{table}"
      end
    end

    puts ""
    puts "🚀 Recreating tables..."

    # Copy only Alto migrations (avoid ActionMailbox/ActionText)
    puts "📦 Installing Alto migrations only..."
    copy_alto_migrations_only

    puts "⚡ Running migrations..."
    system("rake db:migrate")

    puts "✅ Alto database reset completed!"
  end
end

# Helper method to copy only Alto migrations
def copy_alto_migrations_only
    require "fileutils"

    # Get the source migrations directory from the engine
    source_migrations = File.join(::Alto::Engine.root, "db", "migrate")
    destination_migrations = Rails.root.join("db", "migrate")

    # Ensure destination directory exists
    FileUtils.mkdir_p(destination_migrations)

    # Get all Alto migration files
    migration_files = Dir.glob(File.join(source_migrations, "*.rb"))

    if migration_files.empty?
      puts "⚠️  No Alto migrations found"
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

      # Skip if migration already exists (check by class name)
      if migration_already_exists_in_rake?(source_file, destination_migrations)
        puts "   exists    #{new_filename}"
      else
        FileUtils.cp(source_file, destination_file)
        puts "   copied    #{new_filename}"
        copied_count += 1
      end
    end

    if copied_count > 0
      puts "📦 Copied #{copied_count} Alto migration(s)"
    else
      puts "📦 All Alto migrations already present"
    end
  end

  def migration_already_exists_in_rake?(source_file, destination_dir)
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
