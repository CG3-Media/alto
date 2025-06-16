# Start SimpleCov before any code is loaded
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/bin/'
  add_filter '/log/'
  add_filter '/tmp/'
  add_filter '/vendor/'

  # Focus on the main Alto code
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib'

  # Set minimum coverage threshold
  # minimum_coverage 50
end

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Load Rails and required components
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
# require 'action_cable/railtie' # Not used in this engine
require 'active_job/railtie'
require 'active_storage/engine'
require 'rails/test_unit/railtie'
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

# Load test support helpers
require_relative "support/alto_auth_test_helper"
require_relative "support/alto_callback_test_helper"

# Create a simple User model for testing
class User < ActiveRecord::Base
  self.table_name = 'users'
end

# Run all migrations from db/migrate
ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(File.expand_path("../db/migrate", __dir__), ActiveRecord::SchemaMigration).migrate

# Create users table after migrations
unless ActiveRecord::Base.connection.table_exists?('users')
  ActiveRecord::Base.connection.create_table :users do |t|
    t.string :email, null: true  # Allow null for some tests
    t.string :name
    t.timestamps null: false
  end
  ActiveRecord::Base.connection.add_index :users, :email, unique: true
end

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

# Configure proper Rails fixture loading
class ActiveSupport::TestCase
  # Include the AltoAuthTestHelper globally for all tests
  include AltoAuthTestHelper

  # Use transactional rollback for test isolation
  self.use_transactional_tests = true

  # Set fixture path for the engine
  self.fixture_path = File.expand_path("../fixtures", __FILE__)

  # Load all fixtures (Rails convention)
  fixtures :all

  # Map namespaced models to fixture files
  set_fixture_class alto_status_sets: Alto::StatusSet,
                    alto_statuses: Alto::Status,
                    alto_boards: Alto::Board,
                    alto_tags: Alto::Tag,
                    alto_tickets: Alto::Ticket,
                    alto_taggings: Alto::Tagging,
                    alto_fields: Alto::Field

  # Enable parallel testing (Rule #5) - Disabled for in-memory SQLite
  # parallelize(workers: :number_of_processors)

  # Global test isolation: Clear Alto configuration before each test
  # This prevents test pollution where one test's permission configuration
  # affects subsequent tests
  setup do
    # Only clear permissions for integration tests that use AltoAuthTestHelper
    if self.class.included_modules.include?(AltoAuthTestHelper)
      Alto.configuration.permission_methods.clear
    end
  end
end

class ActionDispatch::IntegrationTest
  # Use transactional rollback for integration tests too
  self.use_transactional_tests = true

  include AltoAuthTestHelper
  include AltoCallbackTestHelper
end

class ActiveSupport::TestCase
  include AltoCallbackTestHelper
end
