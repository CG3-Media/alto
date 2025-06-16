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
      t.boolean :viewable_by_public, default: true, null: false
      t.timestamps null: false
    end

    add_index :alto_statuses, :slug, if_not_exists: true
    add_index :alto_statuses, [ :status_set_id, :position ], if_not_exists: true
    add_index :alto_statuses, [ :status_set_id, :slug ], unique: true, if_not_exists: true

    # Boards - different feedback areas (e.g., features, bugs, etc.)
    create_table :alto_boards, if_not_exists: true do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :status_set, foreign_key: { to_table: :alto_status_sets }
      t.string :item_label_singular, default: 'ticket'
      t.boolean :is_admin_only, default: false, null: false
      t.string :single_view
      t.boolean :allow_public_tagging, default: false, null: false
      t.boolean :allow_voting, default: true, null: false
      t.timestamps null: false
    end

    add_index :alto_boards, :name, if_not_exists: true
    add_index :alto_boards, :slug, unique: true, if_not_exists: true
    add_index :alto_boards, :single_view, if_not_exists: true

    # Tickets - main feedback items
    create_table :alto_tickets, if_not_exists: true do |t|
      t.string :title, null: false
      t.text :description
      t.string :status_slug
      t.boolean :locked, default: false, null: false
      t.references :user, null: false, polymorphic: true
      t.references :board, null: false, foreign_key: { to_table: :alto_boards }
      t.boolean :archived, default: false, null: false
      t.text :field_values
      t.timestamps null: false
    end

    add_index :alto_tickets, :status_slug, if_not_exists: true
    add_index :alto_tickets, :locked, if_not_exists: true
    add_index :alto_tickets, :created_at, if_not_exists: true
    add_index :alto_tickets, :title, if_not_exists: true
    add_index :alto_tickets, :description, if_not_exists: true
    add_index :alto_tickets, [ :status_slug, :created_at ], if_not_exists: true
    add_index :alto_tickets, :archived, if_not_exists: true
    add_index :alto_tickets, :field_values, if_not_exists: true

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

    add_index :alto_upvotes, [ :upvotable_type, :upvotable_id, :user_id ],
              unique: true, name: 'index_upvotes_on_upvotable_and_user', if_not_exists: true

    # Subscriptions - email notifications for ticket updates
    create_table :alto_subscriptions, if_not_exists: true do |t|
      t.string :email
      t.references :ticket, foreign_key: { to_table: :alto_tickets }
      t.datetime :last_viewed_at
      t.timestamps null: false
    end

    add_index :alto_subscriptions, :email, if_not_exists: true
    add_index :alto_subscriptions, [ :ticket_id, :email ], unique: true, if_not_exists: true

    # Settings - key-value store for engine configuration
    create_table :alto_settings, if_not_exists: true do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'
      t.timestamps null: false
    end

    add_index :alto_settings, :key, unique: true, if_not_exists: true

    # Fields - custom field definitions for boards
    create_table :alto_fields, if_not_exists: true do |t|
      t.references :board, null: false, foreign_key: { to_table: :alto_boards }
      t.string :label, null: false
      t.string :field_type, null: false  # text_input, textarea, number, date, select, multiselect
      t.text :field_options # JSON for select options
      t.integer :position, default: 0, null: false
      t.boolean :required, default: false, null: false
      t.string :placeholder
      t.text :help_text
      t.timestamps null: false
    end

    add_index :alto_fields, [ :board_id, :position ], if_not_exists: true
    add_index :alto_fields, :field_type, if_not_exists: true

    # Tags - categorization for tickets
    create_table :alto_tags, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :board, null: false, foreign_key: { to_table: :alto_boards }
      t.string :color
      t.integer :usage_count, default: 0, null: false
      t.string :slug
      t.timestamps null: false
    end

    add_index :alto_tags, [:board_id, :name], unique: true, if_not_exists: true
    add_index :alto_tags, [:board_id, :slug], unique: true, if_not_exists: true
    add_index :alto_tags, :usage_count, if_not_exists: true

    # Taggings - join table for tags
    create_table :alto_taggings, if_not_exists: true do |t|
      t.references :tag, null: false, foreign_key: { to_table: :alto_tags }
      t.references :taggable, polymorphic: true, null: false
      t.timestamps null: false
    end

    add_index :alto_taggings, [:tag_id, :taggable_type, :taggable_id], unique: true, name: 'index_alto_taggings_on_tag_and_taggable', if_not_exists: true
    add_index :alto_taggings, [:taggable_type, :taggable_id], if_not_exists: true

    # PostgreSQL-specific trigram search indexes
    if connection.adapter_name.downcase.include?('postgresql')
      enable_extension 'pg_trgm'

      # Add trigram indexes for fuzzy search on tickets
      add_index :alto_tickets, :title,
                using: :gin,
                opclass: :gin_trgm_ops,
                name: 'index_alto_tickets_on_title_trigram',
                if_not_exists: true

      add_index :alto_tickets, :description,
                using: :gin,
                opclass: :gin_trgm_ops,
                name: 'index_alto_tickets_on_description_trigram',
                if_not_exists: true

      # Composite index for both fields combined
      execute <<-SQL
        CREATE INDEX IF NOT EXISTS index_alto_tickets_on_title_description_trigram
        ON alto_tickets USING gin ((title || ' ' || COALESCE(description, '')) gin_trgm_ops);
      SQL
    end
  end

  def down
    # Handle PostgreSQL-specific cleanup first
    if connection.adapter_name.downcase.include?('postgresql')
      remove_index :alto_tickets, name: 'index_alto_tickets_on_title_trigram', if_exists: true
      remove_index :alto_tickets, name: 'index_alto_tickets_on_description_trigram', if_exists: true
      execute "DROP INDEX IF EXISTS index_alto_tickets_on_title_description_trigram;"
      # Note: We don't disable the extension as other tables might use it
    end

    # Drop tables in reverse order of creation
    drop_table :alto_taggings, if_exists: true
    drop_table :alto_tags, if_exists: true
    drop_table :alto_fields, if_exists: true
    drop_table :alto_settings, if_exists: true
    drop_table :alto_subscriptions, if_exists: true
    drop_table :alto_upvotes, if_exists: true
    drop_table :alto_comments, if_exists: true
    drop_table :alto_tickets, if_exists: true
    drop_table :alto_boards, if_exists: true
    drop_table :alto_statuses, if_exists: true
    drop_table :alto_status_sets, if_exists: true
  end
end
