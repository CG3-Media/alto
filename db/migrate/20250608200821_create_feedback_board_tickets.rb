class CreateFeedbackBoardTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_board_tickets do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'open', null: false
      t.boolean :locked, default: false, null: false
      t.integer :user_id, null: false

      t.timestamps
    end
    add_index :feedback_board_tickets, :status
    add_index :feedback_board_tickets, :locked
    add_index :feedback_board_tickets, :user_id
    add_index :feedback_board_tickets, :created_at
  end
end
