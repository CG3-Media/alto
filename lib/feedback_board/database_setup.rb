module FeedbackBoard
  class DatabaseSetup
    def self.setup_if_needed
      return unless should_setup?

      Rails.logger.info "[FeedbackBoard] Setting up database schema..."

      create_tables

      Rails.logger.info "[FeedbackBoard] Database setup complete!"
    end

    # Force database setup regardless of existing tables
    def self.force_setup!
      Rails.logger.info "[FeedbackBoard] Force setting up database schema..."

      create_tables

      Rails.logger.info "[FeedbackBoard] Database setup complete!"
    end

    private

    def self.should_setup?
      # Only setup if we're connected to a database and tables don't exist
      ActiveRecord::Base.connection.present? && !all_tables_exist?
    rescue => e
      Rails.logger.warn "[FeedbackBoard] Could not check database: #{e.message}"
      false
    end

    def self.all_tables_exist?
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
      required_tables.all? { |table| connection.table_exists?(table) }
    end

    # Legacy method name for backward compatibility
    def self.tables_exist?
      all_tables_exist?
    end

    def self.create_tables
      connection = ActiveRecord::Base.connection

      # Create status sets table
      unless connection.table_exists?('feedback_board_status_sets')
        connection.create_table :feedback_board_status_sets do |t|
          t.string :name, null: false
          t.text :description
          t.boolean :is_default, default: false, null: false
          t.timestamps
        end
      end

      # Add indexes for status sets table (check existence first)
      if connection.table_exists?('feedback_board_status_sets')
        add_index_if_not_exists(connection, :feedback_board_status_sets, :name)
        add_index_if_not_exists(connection, :feedback_board_status_sets, :is_default)
      end

      # Create statuses table
      unless connection.table_exists?('feedback_board_statuses')
        connection.create_table :feedback_board_statuses do |t|
          t.references :status_set, null: false, foreign_key: { to_table: :feedback_board_status_sets }
          t.string :name, null: false
          t.string :color, null: false
          t.integer :position, null: false, default: 0
          t.string :slug, null: false
          t.timestamps
        end
      end

      # Add indexes for statuses table (check existence first)
      if connection.table_exists?('feedback_board_statuses')
        add_index_if_not_exists(connection, :feedback_board_statuses, :slug)
        add_index_if_not_exists(connection, :feedback_board_statuses, [:status_set_id, :position])
        add_index_if_not_exists(connection, :feedback_board_statuses, [:status_set_id, :slug], { unique: true })
      end

      # Create boards table
      unless connection.table_exists?('feedback_board_boards')
        connection.create_table :feedback_board_boards do |t|
          t.string :name, null: false
          t.string :slug, null: false
          t.text :description
          t.string :item_label_singular, default: 'ticket'
          t.references :status_set, null: true, foreign_key: { to_table: :feedback_board_status_sets }
          t.timestamps
        end
      end

      # Add indexes for boards table (check existence first)
      if connection.table_exists?('feedback_board_boards')
        add_index_if_not_exists(connection, :feedback_board_boards, :slug, { unique: true })
        add_index_if_not_exists(connection, :feedback_board_boards, :name)
      end

      # Create tickets table
      unless connection.table_exists?('feedback_board_tickets')
        connection.create_table :feedback_board_tickets do |t|
          t.string :title, null: false
          t.text :description
          t.string :status_slug, default: 'open', null: false
          t.boolean :locked, default: false, null: false
          t.integer :user_id, null: false
          t.references :board, null: false, foreign_key: { to_table: :feedback_board_boards }
          t.timestamps
        end
      end

      # Add indexes for tickets table (check existence first)
      if connection.table_exists?('feedback_board_tickets')
        add_index_if_not_exists(connection, :feedback_board_tickets, :status_slug)
        add_index_if_not_exists(connection, :feedback_board_tickets, [:status_slug, :created_at])
        add_index_if_not_exists(connection, :feedback_board_tickets, :locked)
        add_index_if_not_exists(connection, :feedback_board_tickets, :user_id)
        add_index_if_not_exists(connection, :feedback_board_tickets, :created_at)
        add_index_if_not_exists(connection, :feedback_board_tickets, :board_id)
        add_index_if_not_exists(connection, :feedback_board_tickets, :title)
        add_index_if_not_exists(connection, :feedback_board_tickets, :description)
      end

      # Create comments table
      unless connection.table_exists?('feedback_board_comments')
        connection.create_table :feedback_board_comments do |t|
          t.references :ticket, null: false, foreign_key: { to_table: :feedback_board_tickets }
          t.integer :user_id
          t.text :content
          t.references :parent, null: true, foreign_key: { to_table: :feedback_board_comments }
          t.integer :depth, default: 0, null: false
          t.timestamps
        end
      end

      # Add indexes for comments table (check existence first)
      if connection.table_exists?('feedback_board_comments')
        add_index_if_not_exists(connection, :feedback_board_comments, :ticket_id)
        add_index_if_not_exists(connection, :feedback_board_comments, :user_id)
        add_index_if_not_exists(connection, :feedback_board_comments, :parent_id)
        add_index_if_not_exists(connection, :feedback_board_comments, :content)
      end

      # Create upvotes table
      unless connection.table_exists?('feedback_board_upvotes')
        connection.create_table :feedback_board_upvotes do |t|
          t.string :upvotable_type, null: false
          t.integer :upvotable_id, null: false
          t.integer :user_id, null: false
          t.timestamps
        end
      end

      # Add indexes for upvotes table (check existence first)
      if connection.table_exists?('feedback_board_upvotes')
        add_index_if_not_exists(connection, :feedback_board_upvotes, [:upvotable_type, :upvotable_id])
        add_index_if_not_exists(connection, :feedback_board_upvotes, :user_id)
        add_index_if_not_exists(connection, :feedback_board_upvotes, [:upvotable_type, :upvotable_id, :user_id],
                              { unique: true, name: 'index_upvotes_on_upvotable_and_user' })
      end

      # Create settings table
      unless connection.table_exists?('feedback_board_settings')
        connection.create_table :feedback_board_settings do |t|
          t.string :key, null: false
          t.text :value
          t.string :value_type, default: 'string'
          t.timestamps
        end
      end

      # Add indexes for settings table (check existence first)
      if connection.table_exists?('feedback_board_settings')
        add_index_if_not_exists(connection, :feedback_board_settings, :key, { unique: true })
      end
    end

    def self.add_index_if_not_exists(connection, table_name, column_or_options, options = {})
      # Handle both simple column names and complex options
      if column_or_options.is_a?(Array) && options.present?
        # Complex case: multiple columns with options
        index_name = options[:name] || "index_#{table_name}_on_#{column_or_options.join('_and_')}"
        return if connection.index_exists?(table_name, column_or_options, name: index_name)
        connection.add_index(table_name, column_or_options, options)
      elsif column_or_options.is_a?(Array)
        # Simple case: multiple columns, no special options
        return if connection.index_exists?(table_name, column_or_options)
        connection.add_index(table_name, column_or_options)
      else
        # Simple case: single column
        return if connection.index_exists?(table_name, column_or_options)
        connection.add_index(table_name, column_or_options)
      end
    rescue => e
      Rails.logger.warn "[FeedbackBoard] Could not add index: #{e.message}"
    end
  end
end
