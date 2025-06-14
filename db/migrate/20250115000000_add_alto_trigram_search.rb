class AddAltoTrigramSearch < ActiveRecord::Migration[7.0]
  def up
    # Only run for PostgreSQL databases
    return unless connection.adapter_name.downcase.include?('postgresql')

    # Enable pg_trgm extension for trigram similarity search
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

  def down
    return unless connection.adapter_name.downcase.include?('postgresql')

    remove_index :alto_tickets, name: 'index_alto_tickets_on_title_trigram', if_exists: true
    remove_index :alto_tickets, name: 'index_alto_tickets_on_description_trigram', if_exists: true
    execute "DROP INDEX IF EXISTS index_alto_tickets_on_title_description_trigram;"

    # Note: We don't disable the extension as other tables might use it
  end
end
