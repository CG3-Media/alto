class CreateFeedbackBoardStatusSets < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_board_status_sets do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :feedback_board_status_sets, :name
    add_index :feedback_board_status_sets, :is_default
  end
end
