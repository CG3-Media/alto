class CreateFeedbackBoardUpvotes < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_board_upvotes do |t|
      t.references :upvotable, polymorphic: true, null: false
      t.integer :user_id, null: false

      t.timestamps
    end
    add_index :feedback_board_upvotes, :user_id
    add_index :feedback_board_upvotes, [:upvotable_type, :upvotable_id, :user_id],
              unique: true, name: 'index_upvotes_on_upvotable_and_user'
  end
end
