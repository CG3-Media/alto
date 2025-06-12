class CreateAltoTaggings < ActiveRecord::Migration[7.0]
  def change
    create_table :alto_taggings do |t|
      t.references :tag, null: false, foreign_key: { to_table: :alto_tags }
      t.references :taggable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :alto_taggings, [:tag_id, :taggable_type, :taggable_id], unique: true, name: 'index_alto_taggings_on_tag_and_taggable'
    add_index :alto_taggings, [:taggable_type, :taggable_id]
  end
end