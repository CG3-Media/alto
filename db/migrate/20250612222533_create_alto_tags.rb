class CreateAltoTags < ActiveRecord::Migration[7.0]
  def change
    create_table :alto_tags do |t|
      t.string :name, null: false
      t.references :board, null: false, foreign_key: { to_table: :alto_boards }
      t.string :color
      t.integer :usage_count, default: 0, null: false
      t.string :slug

      t.timestamps
    end

    add_index :alto_tags, [:board_id, :name], unique: true
    add_index :alto_tags, [:board_id, :slug], unique: true
    add_index :alto_tags, :usage_count
  end
end