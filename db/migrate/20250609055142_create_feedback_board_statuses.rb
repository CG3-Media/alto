class CreateFeedbackBoardStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_board_statuses do |t|
      t.references :status_set, null: false, foreign_key: { to_table: :feedback_board_status_sets }
      t.string :name, null: false
      t.string :color, null: false
      t.integer :position, null: false, default: 0
      t.string :slug, null: false

      t.timestamps
    end

    add_index :feedback_board_statuses, :slug
    add_index :feedback_board_statuses, [:status_set_id, :position]
    add_index :feedback_board_statuses, [:status_set_id, :slug], unique: true
  end
end
