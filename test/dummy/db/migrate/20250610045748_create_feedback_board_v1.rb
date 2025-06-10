class CreateFeedbackBoardV1 < ActiveRecord::Migration[7.0]
  def change
    # Status Sets - templates for status workflows
    create_table :feedback_board_status_sets, if_not_exists: true do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_default, default: false, null: false
      t.timestamps null: false
    end

    add_index :feedback_board_status_sets, :name
    add_index :feedback_board_status_sets, :is_default

    # Statuses - individual statuses within status sets
    create_table :feedback_board_statuses, if_not_exists: true do |t|
      t.references :status_set, null: false, foreign_key: { to_table: :feedback_board_status_sets }
      t.string :name, null: false
      t.string :color, null: false
      t.integer :position, default: 0, null: false
      t.string :slug, null: false
      t.timestamps null: false
    end

    add_index :feedback_board_statuses, :slug
    add_index :feedback_board_statuses, [:status_set_id, :position]
    add_index :feedback_board_statuses, [:status_set_id, :slug], unique: true

    # Boards - different feedback areas (e.g., features, bugs, etc.)
    create_table :feedback_board_boards, if_not_exists: true do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :status_set, foreign_key: { to_table: :feedback_board_status_sets }
      t.string :item_label_singular, default: 'ticket'
      t.timestamps null: false
    end

    add_index :feedback_board_boards, :name
    add_index :feedback_board_boards, :slug, unique: true

    # Tickets - main feedback items
    create_table :feedback_board_tickets, if_not_exists: true do |t|
      t.string :title, null: false
      t.text :description
      t.string :status_slug
      t.boolean :locked, default: false, null: false
      t.references :user, null: false, polymorphic: true
      t.references :board, null: false, foreign_key: { to_table: :feedback_board_boards }
      t.timestamps null: false
    end

    add_index :feedback_board_tickets, :status_slug
    add_index :feedback_board_tickets, :locked
    add_index :feedback_board_tickets, :created_at
    add_index :feedback_board_tickets, :title
    add_index :feedback_board_tickets, :description
    add_index :feedback_board_tickets, [:status_slug, :created_at]

    # Comments - threaded discussions on tickets
    create_table :feedback_board_comments, if_not_exists: true do |t|
      t.references :ticket, null: false, foreign_key: { to_table: :feedback_board_tickets }
      t.references :user, polymorphic: true
      t.references :parent, foreign_key: { to_table: :feedback_board_comments }
      t.text :content
      t.integer :depth, default: 0, null: false
      t.timestamps null: false
    end

    add_index :feedback_board_comments, :content

        # Upvotes - voting system for tickets and comments
    create_table :feedback_board_upvotes, if_not_exists: true do |t|
      t.references :upvotable, null: false, polymorphic: true
      t.references :user, null: false, polymorphic: true
      t.timestamps null: false
    end

    add_index :feedback_board_upvotes, [:upvotable_type, :upvotable_id, :user_id],
              unique: true, name: 'index_upvotes_on_upvotable_and_user'

    # Subscriptions - email notifications for ticket updates
    create_table :feedback_board_subscriptions, if_not_exists: true do |t|
      t.string :email
      t.references :ticket, foreign_key: { to_table: :feedback_board_tickets }
      t.datetime :last_viewed_at
      t.timestamps null: false
    end

    add_index :feedback_board_subscriptions, :email
    add_index :feedback_board_subscriptions, [:ticket_id, :email], unique: true

    # Settings - key-value store for engine configuration
    create_table :feedback_board_settings, if_not_exists: true do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'
      t.timestamps null: false
    end

    add_index :feedback_board_settings, :key, unique: true
  end
end
