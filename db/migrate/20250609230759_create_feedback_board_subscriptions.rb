class CreateFeedbackBoardSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :feedback_board_subscriptions do |t|
      t.string :email
      t.integer :ticket_id
      t.datetime :last_viewed_at

      t.timestamps
    end

    add_index :feedback_board_subscriptions, :email
    add_index :feedback_board_subscriptions, :ticket_id
    add_index :feedback_board_subscriptions, [:ticket_id, :email], unique: true
    add_foreign_key :feedback_board_subscriptions, :feedback_board_tickets, column: :ticket_id
  end
end
