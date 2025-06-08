class CreateFeedbackBoardComments < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_board_comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.integer :user_id
      t.text :content

      t.timestamps
    end
    add_index :feedback_board_comments, :user_id
  end
end
