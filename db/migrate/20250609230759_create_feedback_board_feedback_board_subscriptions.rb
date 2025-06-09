class CreateFeedbackBoardFeedbackBoardSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :feedback_board_feedback_board_subscriptions do |t|
      t.string :email
      t.integer :ticket_id
      t.datetime :last_viewed_at

      t.timestamps
    end
  end
end
