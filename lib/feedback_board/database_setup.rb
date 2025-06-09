module FeedbackBoard
  class DatabaseSetup
    def self.setup_if_needed
      return unless should_setup?

      Rails.logger.info "[FeedbackBoard] Setting up database schema..."

      create_tables
      create_default_data

      Rails.logger.info "[FeedbackBoard] Database setup complete!"
    end

    private

    def self.should_setup?
      # Only setup if we're connected to a database and tables don't exist
      ActiveRecord::Base.connection.present? && !tables_exist?
    rescue => e
      Rails.logger.warn "[FeedbackBoard] Could not check database: #{e.message}"
      false
    end

    def self.tables_exist?
      ActiveRecord::Base.connection.table_exists?('feedback_board_tickets') &&
      ActiveRecord::Base.connection.table_exists?('feedback_board_status_sets')
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
        connection.add_index :feedback_board_status_sets, :name
        connection.add_index :feedback_board_status_sets, :is_default
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
        connection.add_index :feedback_board_statuses, :slug
        connection.add_index :feedback_board_statuses, [:status_set_id, :position]
        connection.add_index :feedback_board_statuses, [:status_set_id, :slug], unique: true
      end

      # Create boards table
      unless connection.table_exists?('feedback_board_boards')
        connection.create_table :feedback_board_boards do |t|
          t.string :name, null: false
          t.string :slug, null: false
          t.text :description
          t.references :status_set, null: true, foreign_key: { to_table: :feedback_board_status_sets }
          t.timestamps
        end
        connection.add_index :feedback_board_boards, :slug, unique: true
        connection.add_index :feedback_board_boards, :name
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
        connection.add_index :feedback_board_tickets, :status_slug
        connection.add_index :feedback_board_tickets, [:status_slug, :created_at]
        connection.add_index :feedback_board_tickets, :locked
        connection.add_index :feedback_board_tickets, :user_id
        connection.add_index :feedback_board_tickets, :created_at
        connection.add_index :feedback_board_tickets, :board_id
        connection.add_index :feedback_board_tickets, :title
        connection.add_index :feedback_board_tickets, :description
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
        connection.add_index :feedback_board_comments, :ticket_id
        connection.add_index :feedback_board_comments, :user_id
        connection.add_index :feedback_board_comments, :parent_id
        connection.add_index :feedback_board_comments, :content
      end

      # Create upvotes table
      unless connection.table_exists?('feedback_board_upvotes')
        connection.create_table :feedback_board_upvotes do |t|
          t.string :upvotable_type, null: false
          t.integer :upvotable_id, null: false
          t.integer :user_id, null: false
          t.timestamps
        end
        connection.add_index :feedback_board_upvotes, [:upvotable_type, :upvotable_id]
        connection.add_index :feedback_board_upvotes, :user_id
        connection.add_index :feedback_board_upvotes, [:upvotable_type, :upvotable_id, :user_id],
                           unique: true, name: 'index_upvotes_on_upvotable_and_user'
      end

      # Create settings table
      unless connection.table_exists?('feedback_board_settings')
        connection.create_table :feedback_board_settings do |t|
          t.string :key, null: false
          t.text :value
          t.string :value_type, default: 'string'
          t.timestamps
        end
        connection.add_index :feedback_board_settings, :key, unique: true
      end
    end

    def self.create_default_data
      return if FeedbackBoard::StatusSet.exists? # Don't recreate if data exists

      now = Time.current

      # Create default status sets
      dev_set = FeedbackBoard::StatusSet.create!(
        name: 'Development Lifecycle',
        description: 'Full product development lifecycle with all stages',
        is_default: true
      )

      simple_set = FeedbackBoard::StatusSet.create!(
        name: 'Simple Open/Closed',
        description: 'Basic open and closed statuses only'
      )

      no_status_set = FeedbackBoard::StatusSet.create!(
        name: 'No Status Tracking',
        description: 'Board without status tracking - just collect feedback'
      )

      # Create statuses for development lifecycle
      [
        ['Open', 'green', 0, 'open'],
        ['Planned', 'blue', 1, 'planned'],
        ['In Progress', 'yellow', 2, 'in_progress'],
        ['Complete', 'gray', 3, 'complete']
      ].each do |name, color, position, slug|
        dev_set.statuses.create!(
          name: name,
          color: color,
          position: position,
          slug: slug
        )
      end

      # Create statuses for simple set
      [
        ['Open', 'green', 0, 'open'],
        ['Closed', 'gray', 1, 'closed']
      ].each do |name, color, position, slug|
        simple_set.statuses.create!(
          name: name,
          color: color,
          position: position,
          slug: slug
        )
      end

      # No Status Tracking has no statuses (empty set)

      # Create default board
      unless FeedbackBoard::Board.exists?
        FeedbackBoard::Board.create!(
          name: 'Feedback',
          slug: 'feedback',
          description: 'General feedback and feature requests',
          status_set: dev_set
        )
      end
    end
  end
end
