# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Load Rails and required components
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_storage/engine'
require 'sqlite3'

# Load the engine BEFORE creating the Rails app
require_relative "../lib/alto"

# Configure Alto for testing
Alto.configure do |config|
  config.image_uploads_enabled = true
  config.user_model = "User"
end

# Create a minimal Rails application for testing
class TestApp < Rails::Application
  config.load_defaults 7.0
  config.eager_load = false
  config.cache_classes = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Disable migration check since we run migrations manually
  config.active_record.maintain_test_schema = false

  # Configure ActiveStorage for testing
  config.active_storage.service = :test
end

# Initialize the Rails application
TestApp.initialize!

# Add routes after initialization
TestApp.routes.draw do
  mount Alto::Engine => "/"
end

# Set up in-memory SQLite database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Configure ActiveStorage test service
Rails.application.config.active_storage.service_configurations = {
  test: {
    service: "Disk",
    root: Rails.root.join("tmp/storage")
  }
}

# Load Rails test framework
require "rails/test_help"

# Load ApplicationController first
require_relative "../app/controllers/alto/application_controller"

# Run migrations directly
require_relative "../db/migrate/20250115000000_add_alto_trigram_search"
require_relative "../db/migrate/20250611235259_create_alto_v1"
require_relative "../db/migrate/20250611235260_add_single_view_to_alto_boards"
require_relative "../db/migrate/20250611235261_create_alto_fields"
require_relative "../db/migrate/20250612025738_add_archived_to_alto_tickets"
require_relative "../db/migrate/20250612222533_create_alto_tags"
require_relative "../db/migrate/20250612222534_create_alto_taggings"
require_relative "../db/migrate/20250612222535_add_allow_public_tagging_to_alto_boards"
require_relative "../db/migrate/20250613230849_add_viewable_by_public_to_alto_statuses"
require_relative "../db/migrate/20250614005311_add_allow_voting_to_alto_boards"

# Create a simple User model for testing
class User < ActiveRecord::Base
  self.table_name = 'users'

  # Create users table if it doesn't exist
  unless connection.table_exists?('users')
    connection.create_table :users do |t|
      t.string :email, null: true  # Allow null for some tests
      t.string :name
      t.timestamps null: false
    end
    connection.add_index :users, :email, unique: true
  end
end

# Run migrations properly
AddAltoTrigramSearch.migrate(:up)
CreateAltoV1.migrate(:up)
AddSingleViewToAltoBoards.migrate(:up)
CreateAltoFields.migrate(:up)
AddArchivedToAltoTickets.migrate(:up)
CreateAltoTags.migrate(:up)
CreateAltoTaggings.migrate(:up)
AddAllowPublicTaggingToAltoBoards.migrate(:up)
AddViewableByPublicToAltoStatuses.migrate(:up)
AddAllowVotingToAltoBoards.migrate(:up)

# Create ActiveStorage tables manually for testing
ActiveRecord::Base.connection.create_table :active_storage_blobs, if_not_exists: true do |t|
  t.string   :key,          null: false
  t.string   :filename,     null: false
  t.string   :content_type
  t.text     :metadata
  t.string   :service_name, null: false
  t.bigint   :byte_size,    null: false
  t.string   :checksum
  t.datetime :created_at,   null: false

  t.index [ :key ], unique: true
end

ActiveRecord::Base.connection.create_table :active_storage_attachments, if_not_exists: true do |t|
  t.string     :name,     null: false
  t.references :record,   null: false, polymorphic: true, index: false
  t.references :blob,     null: false

  t.datetime :created_at, null: false

  t.index [ :record_type, :record_id, :name, :blob_id ], name: "index_active_storage_attachments_uniqueness", unique: true
  t.foreign_key :active_storage_blobs, column: :blob_id
end

ActiveRecord::Base.connection.create_table :active_storage_variant_records, if_not_exists: true do |t|
  t.belongs_to :blob, null: false, index: false
  t.string :variation_digest, null: false

  t.index %i[ blob_id variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
  t.foreign_key :active_storage_blobs, column: :blob_id
end

# Configure proper test isolation strategy
class ActiveSupport::TestCase
  # Use transactional rollback for test isolation instead of manual cleanup
  self.use_transactional_tests = true

  # Create test data that tests expect
  def setup
    super
    create_test_data unless @test_data_created
    @test_data_created = true
  end

  private

  def create_test_data
    # Create test users first
    @user_one = User.find_or_create_by(email: "user1@example.com") do |user|
      user.name = "Test User One"
    end

    @user_two = User.find_or_create_by(email: "user2@example.com") do |user|
      user.name = "Test User Two"
    end

    @user_three = User.find_or_create_by(email: "user3@example.com") do |user|
      user.name = "Test User Three"
    end

    # Create user without email for specific tests
    @user_no_email = User.create!(name: "User Without Email")

    # Create default status set that tests expect
    @default_status_set = Alto::StatusSet.find_or_create_by(name: "Default Status Set") do |status_set|
      status_set.is_default = true
      status_set.description = "Default status set for testing"
    end

    # Create default statuses (tests expect 3 statuses)
    @open_status = @default_status_set.statuses.find_or_create_by(slug: "open") do |status|
      status.name = "Open"
      status.color = "green"
      status.position = 0
    end

    @in_progress_status = @default_status_set.statuses.find_or_create_by(slug: "in_progress") do |status|
      status.name = "In Progress"
      status.color = "yellow"
      status.position = 1
    end

    @closed_status = @default_status_set.statuses.find_or_create_by(slug: "closed") do |status|
      status.name = "Closed"
      status.color = "red"
      status.position = 2
    end

    # Create test boards that tests expect
    @bugs_board = Alto::Board.find_or_create_by(slug: "bugs") do |board|
      board.name = "Bug Reports"
      board.description = "Report bugs here"
      board.status_set = @default_status_set
      board.is_admin_only = false
      board.item_label_singular = "bug"
    end

    # Create required fields for bugs board (expected by tests)
    @bugs_board.fields.find_or_create_by(label: "Severity") do |field|
      field.field_type = "select"
      field.field_options = ["Low", "Medium", "High", "Critical"]
      field.required = true
      field.position = 0
    end

    @bugs_board.fields.find_or_create_by(label: "Steps to Reproduce") do |field|
      field.field_type = "textarea"
      field.required = true
      field.position = 1
    end

    @general_board = Alto::Board.find_or_create_by(slug: "general") do |board|
      board.name = "General Feedback"
      board.description = "General feedback and suggestions"
      board.status_set = @default_status_set
      board.is_admin_only = false
      board.item_label_singular = "ticket"
    end

    # Create test tickets that tests expect
    @ticket_one = Alto::Ticket.find_or_create_by(title: "Dark mode implementation") do |ticket|
      ticket.description = "Add dark theme support to the application"
      ticket.status_slug = "open"
      ticket.board = @bugs_board
      ticket.user_id = @user_one.id
      ticket.user_type = "User"
    end

    @ticket_two = Alto::Ticket.find_or_create_by(title: "Bug in user login") do |ticket|
      ticket.description = "Users cannot log in with special characters in password"
      ticket.status_slug = "in_progress"
      ticket.board = @bugs_board
      ticket.user_id = @user_two.id
      ticket.user_type = "User"
    end

    @ticket_three = Alto::Ticket.find_or_create_by(title: "User preferences") do |ticket|
      ticket.description = "Allow users to save their preferred settings"
      ticket.status_slug = "open"
      ticket.board = @general_board
      ticket.user_id = @user_three.id
      ticket.user_type = "User"
    end

    # Create test comments that tests expect (only if tickets exist)
    if @ticket_one&.persisted?
      @comment_one = Alto::Comment.find_or_create_by(
        content: "This is a great idea!",
        ticket: @ticket_one,
        user_id: @user_two.id,
        user_type: "User"
      )

      @comment_two = Alto::Comment.find_or_create_by(
        content: "I agree, this would be very useful",
        ticket: @ticket_one,
        user_id: @user_three.id,
        user_type: "User"
      )
    end
  end

  # Helper method to access status set like fixtures
  def alto_status_sets(name)
    case name
    when :default
      @default_status_set || create_test_data && @default_status_set
    else
      nil
    end
  end

  # Helper method to access boards like fixtures
  def alto_boards(name)
    case name
    when :bugs
      @bugs_board || create_test_data && @bugs_board
    when :general
      @general_board || create_test_data && @general_board
    else
      nil
    end
  end

  # Helper method to access tickets like fixtures
  def alto_tickets(name)
    case name
    when :one
      @ticket_one || create_test_data && @ticket_one
    when :two
      @ticket_two || create_test_data && @ticket_two
    when :three
      @ticket_three || create_test_data && @ticket_three
    else
      nil
    end
  end

  # Helper method to access comments like fixtures
  def alto_comments(name)
    case name
    when :one
      @comment_one || create_test_data && @comment_one
    when :two
      @comment_two || create_test_data && @comment_two
    else
      nil
    end
  end

  # Helper method to access users like fixtures
  def users(name)
    case name
    when :one
      @user_one || create_test_data && @user_one
    when :two
      @user_two || create_test_data && @user_two
    when :three
      @user_three || create_test_data && @user_three
    when :no_email
      @user_no_email || create_test_data && @user_no_email
    else
      nil
    end
  end
end

class ActionDispatch::IntegrationTest
  # Use transactional rollback for integration tests too
  self.use_transactional_tests = true
end
