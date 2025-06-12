# This migration comes from alto (originally 20250114000002)
class CreateAltoFields < ActiveRecord::Migration[7.0]
  def change
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

    add_index :alto_fields, [:board_id, :position], if_not_exists: true
    add_index :alto_fields, :field_type, if_not_exists: true

    # Add custom field values to tickets
    add_column :alto_tickets, :field_values, :text, if_not_exists: true
    add_index :alto_tickets, :field_values, if_not_exists: true
  end
end
