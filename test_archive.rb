#!/usr/bin/env ruby

# Simple standalone test for archive functionality
require_relative 'test/dummy/config/environment'

puts "🎯 Testing Archive Functionality"
puts "=" * 50

# Create test data
puts "Creating test data..."

# Create status set
status_set = Alto::StatusSet.find_or_create_by!(name: 'Test Status Set') do |ss|
  ss.is_default = true
end

unless status_set.statuses.exists?
  status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')
  status_set.statuses.create!(name: 'Closed', color: 'gray', position: 1, slug: 'closed')
end

# Create board
board = Alto::Board.find_or_create_by!(name: 'Test Board') do |b|
  b.status_set = status_set
end

# Create user (simple hash simulation)
user_id = 1

puts "✅ Test data created"

# Test 1: Create regular ticket
puts "\n📝 Test 1: Creating regular ticket"
ticket = Alto::Ticket.create!(
  title: "Test Archive Ticket",
  description: "Testing archive functionality",
  user_id: user_id,
  board: board
)

puts "   Ticket created with ID: #{ticket.id}"
puts "   archived? = #{ticket.archived?}"
puts "   locked? = #{ticket.locked?}"

if !ticket.archived? && !ticket.locked?
  puts "   ✅ PASS: Regular ticket is not archived and not locked"
else
  puts "   ❌ FAIL: Regular ticket should not be archived or locked"
end

# Test 2: Archive ticket
puts "\n📦 Test 2: Archiving ticket"
ticket.update!(archived: true)
ticket.reload

puts "   archived? = #{ticket.archived?}"
puts "   locked? = #{ticket.locked?}"

if ticket.archived? && ticket.locked?
  puts "   ✅ PASS: Archived ticket is archived and locked"
else
  puts "   ❌ FAIL: Archived ticket should be archived and locked"
end

# Test 3: Unarchive ticket
puts "\n📤 Test 3: Unarchiving ticket"
ticket.update!(archived: false)
ticket.reload

puts "   archived? = #{ticket.archived?}"
puts "   locked? = #{ticket.locked?}"

if !ticket.archived? && !ticket.locked?
  puts "   ✅ PASS: Unarchived ticket is not archived and not locked"
else
  puts "   ❌ FAIL: Unarchived ticket should not be archived or locked"
end

# Test 4: Test scopes
puts "\n🔍 Test 4: Testing scopes"

# Create another ticket and archive it
archived_ticket = Alto::Ticket.create!(
  title: "Archived Ticket",
  description: "This will be archived",
  user_id: user_id,
  board: board,
  archived: true
)

active_tickets = Alto::Ticket.active
archived_tickets = Alto::Ticket.archived

puts "   Total tickets: #{Alto::Ticket.count}"
puts "   Active tickets: #{active_tickets.count}"
puts "   Archived tickets: #{archived_tickets.count}"

if active_tickets.include?(ticket) && !active_tickets.include?(archived_ticket)
  puts "   ✅ PASS: Active scope works correctly"
else
  puts "   ❌ FAIL: Active scope not working"
end

if archived_tickets.include?(archived_ticket) && !archived_tickets.include?(ticket)
  puts "   ✅ PASS: Archived scope works correctly"
else
  puts "   ❌ FAIL: Archived scope not working"
end

puts "\n🎉 Archive functionality test completed!"
