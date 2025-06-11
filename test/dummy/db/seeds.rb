# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create a test user first
user = User.find_or_create_by!(email: 'test@example.com')

# Create Status Sets
default_status_set = Alto::StatusSet.find_or_create_by!(name: 'General Feedback') do |ss|
  ss.description = 'Standard status tracking for general feedback'
  ss.is_default = true
end

# Create statuses for the default set
if default_status_set.statuses.empty?
  default_status_set.statuses.create!([
    { name: 'Open', slug: 'open', color: 'green', position: 0 },
    { name: 'Under Review', slug: 'under-review', color: 'blue', position: 1 },
    { name: 'In Progress', slug: 'in-progress', color: 'yellow', position: 2 },
    { name: 'Completed', slug: 'completed', color: 'purple', position: 3 },
    { name: 'Closed', slug: 'closed', color: 'gray', position: 4 }
  ])
end

# Create a development-specific status set
dev_status_set = Alto::StatusSet.find_or_create_by!(name: 'Development Workflow') do |ss|
  ss.description = 'Status tracking for development tasks'
  ss.is_default = false
end

if dev_status_set.statuses.empty?
  dev_status_set.statuses.create!([
    { name: 'Backlog', slug: 'backlog', color: 'gray', position: 0 },
    { name: 'To Do', slug: 'todo', color: 'blue', position: 1 },
    { name: 'In Development', slug: 'in-development', color: 'yellow', position: 2 },
    { name: 'Code Review', slug: 'code-review', color: 'orange', position: 3 },
    { name: 'Testing', slug: 'testing', color: 'purple', position: 4 },
    { name: 'Done', slug: 'done', color: 'green', position: 5 }
  ])
end

# Create Boards (now required to have status sets)
feedback_board = Alto::Board.find_or_create_by!(slug: 'feedback') do |board|
  board.name = 'General Feedback'
  board.description = 'Share your thoughts and suggestions'
  board.status_set = default_status_set
  board.item_label_singular = 'feedback'
  board.is_admin_only = false
end

# Ensure the feedback board is set to list-only view
feedback_board.update!(single_view: 'list')

features_board = Alto::Board.find_or_create_by!(slug: 'features') do |board|
  board.name = 'Feature Requests'
  board.description = 'Request new features and enhancements'
  board.status_set = dev_status_set
  board.item_label_singular = 'request'
  board.is_admin_only = false
end

bugs_board = Alto::Board.find_or_create_by!(slug: 'bugs') do |board|
  board.name = 'Bug Reports'
  board.description = 'Report bugs and issues'
  board.status_set = dev_status_set
  board.item_label_singular = 'bug'
  board.is_admin_only = false
end

# Create some sample tickets (let default status be set automatically)
if feedback_board.tickets.empty?
  ticket1 = feedback_board.tickets.create!(
    title: 'Love the new interface!',
    description: 'The new design is much cleaner and easier to use.',
    user: user
  )

  ticket2 = feedback_board.tickets.create!(
    title: 'Could use better documentation',
    description: 'It would be helpful to have more detailed guides for new users.',
    user: user
  )

  # Update status after creation to avoid validation issues
  ticket2.update!(status_slug: 'under-review') if default_status_set.status_slugs.include?('under-review')
end

if features_board.tickets.empty?
  ticket3 = features_board.tickets.create!(
    title: 'Add dark mode support',
    description: 'Would love to have a dark theme option for better viewing at night.',
    user: user
  )

  ticket4 = features_board.tickets.create!(
    title: 'Export data to CSV',
    description: 'Need ability to export reports and data in CSV format.',
    user: user
  )

  # Update status after creation to avoid validation issues
  ticket4.update!(status_slug: 'todo') if dev_status_set.status_slugs.include?('todo')
end

if bugs_board.tickets.empty?
  bugs_board.tickets.create!(
    title: 'Search not working on mobile',
    description: 'The search function seems to be broken on mobile devices.',
    user: user
  )
end

puts "✅ Seed data created successfully!"
puts "📊 Status Sets: #{Alto::StatusSet.count}"
puts "📋 Boards: #{Alto::Board.count}"
puts "🎫 Tickets: #{Alto::Ticket.count}"
