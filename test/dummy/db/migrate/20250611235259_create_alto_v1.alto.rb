# This migration comes from alto (originally 20250101000000)
class CreateAltoV1 < ActiveRecord::Migration[7.0]
  def change
    # Status Sets - templates for status workflows
    create_table :alto_status_sets, if_not_exists: true do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_default, default: false, null: false
      t.timestamps null: false
    end

    add_index :alto_status_sets, :name, if_not_exists: true
    add_index :alto_status_sets, :is_default, if_not_exists: true

    # Statuses - individual statuses within status sets
    create_table :alto_statuses, if_not_exists: true do |t|
      t.references :status_set, null: false, foreign_key: { to_table: :alto_status_sets }
      t.string :name, null: false
      t.string :color, null: false
      t.integer :position, default: 0, null: false
      t.string :slug, null: false
      t.timestamps null: false
    end

    add_index :alto_statuses, :slug, if_not_exists: true
    add_index :alto_statuses, [:status_set_id, :position], if_not_exists: true
    add_index :alto_statuses, [:status_set_id, :slug], unique: true, if_not_exists: true

    # Boards - different feedback areas (e.g., features, bugs, etc.)
    create_table :alto_boards, if_not_exists: true do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :status_set, foreign_key: { to_table: :alto_status_sets }
      t.string :item_label_singular, default: 'ticket'
      t.boolean :is_admin_only, default: false, null: false
      t.timestamps null: false
    end

    add_index :alto_boards, :name, if_not_exists: true
    add_index :alto_boards, :slug, unique: true, if_not_exists: true

    # Tickets - main feedback items
    create_table :alto_tickets, if_not_exists: true do |t|
      t.string :title, null: false
      t.text :description
      t.string :status_slug
      t.boolean :locked, default: false, null: false
      t.references :user, null: false, polymorphic: true
      t.references :board, null: false, foreign_key: { to_table: :alto_boards }
      t.timestamps null: false
    end

    add_index :alto_tickets, :status_slug, if_not_exists: true
    add_index :alto_tickets, :locked, if_not_exists: true
    add_index :alto_tickets, :created_at, if_not_exists: true
    add_index :alto_tickets, :title, if_not_exists: true
    add_index :alto_tickets, :description, if_not_exists: true
    add_index :alto_tickets, [:status_slug, :created_at], if_not_exists: true

    # Comments - threaded discussions on tickets
    create_table :alto_comments, if_not_exists: true do |t|
      t.references :ticket, null: false, foreign_key: { to_table: :alto_tickets }
      t.references :user, polymorphic: true
      t.references :parent, foreign_key: { to_table: :alto_comments }
      t.text :content
      t.integer :depth, default: 0, null: false
      t.timestamps null: false
    end

    add_index :alto_comments, :content, if_not_exists: true

    # Upvotes - voting system for tickets and comments
    create_table :alto_upvotes, if_not_exists: true do |t|
      t.references :upvotable, null: false, polymorphic: true
      t.references :user, null: false, polymorphic: true
      t.timestamps null: false
    end

    add_index :alto_upvotes, [:upvotable_type, :upvotable_id, :user_id],
              unique: true, name: 'index_upvotes_on_upvotable_and_user', if_not_exists: true

    # Subscriptions - email notifications for ticket updates
    create_table :alto_subscriptions, if_not_exists: true do |t|
      t.string :email
      t.references :ticket, foreign_key: { to_table: :alto_tickets }
      t.datetime :last_viewed_at
      t.timestamps null: false
    end

    add_index :alto_subscriptions, :email, if_not_exists: true
    add_index :alto_subscriptions, [:ticket_id, :email], unique: true, if_not_exists: true

    # Settings - key-value store for engine configuration
    create_table :alto_settings, if_not_exists: true do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'
      t.timestamps null: false
    end

    add_index :alto_settings, :key, unique: true, if_not_exists: true
  end
end
