class CreateFeedbackBoardSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_board_settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'

      t.timestamps
    end

    add_index :feedback_board_settings, :key, unique: true
  end
end
