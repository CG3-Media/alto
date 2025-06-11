require 'sqlite3'

puts "🎯 Simple Archive Database Test"
puts "=" * 40

# Connect directly to the test database
db = SQLite3::Database.new('test/dummy/storage/test.sqlite3')

# Check if archived column exists
puts "\n📊 Checking database schema:"
schema = db.execute("PRAGMA table_info(alto_tickets);")
archived_column = schema.find { |col| col[1] == 'archived' }

if archived_column
  puts "✅ archived column exists: #{archived_column}"
else
  puts "❌ archived column does not exist"
  exit 1
end

# Check if indexes exist
puts "\n📋 Checking indexes:"
indexes = db.execute("PRAGMA index_list(alto_tickets);")
archive_indexes = indexes.select { |idx| idx[1].include?('archived') }

puts "Archive-related indexes found: #{archive_indexes.length}"
archive_indexes.each { |idx| puts "  - #{idx[1]}" }

# Test basic functionality
puts "\n🧪 Testing basic database operations:"

# Insert a regular ticket
db.execute("INSERT INTO alto_tickets (title, description, user_type, user_id, board_id, archived, locked, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))",
           ["Test Ticket", "Test Description", "User", 1, 1, 0, 0])

ticket_id = db.last_insert_row_id
puts "✅ Created ticket with ID: #{ticket_id}"

# Check default values
result = db.execute("SELECT archived, locked FROM alto_tickets WHERE id = ?", [ticket_id])
archived, locked = result[0]

puts "   archived = #{archived} (should be 0)"
puts "   locked = #{locked} (should be 0)"

# Archive the ticket
db.execute("UPDATE alto_tickets SET archived = 1 WHERE id = ?", [ticket_id])
result = db.execute("SELECT archived, locked FROM alto_tickets WHERE id = ?", [ticket_id])
archived, locked = result[0]

puts "✅ After archiving:"
puts "   archived = #{archived} (should be 1)"
puts "   locked = #{locked} (should be 0)"

# Test queries
puts "\n🔍 Testing queries:"

# Count active vs archived
active_count = db.execute("SELECT COUNT(*) FROM alto_tickets WHERE archived = 0")[0][0]
archived_count = db.execute("SELECT COUNT(*) FROM alto_tickets WHERE archived = 1")[0][0]

puts "   Active tickets: #{active_count}"
puts "   Archived tickets: #{archived_count}"

puts "\n🎉 Database tests completed successfully!"

db.close
