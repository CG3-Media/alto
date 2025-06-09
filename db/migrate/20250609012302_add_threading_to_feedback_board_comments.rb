class AddThreadingToFeedbackBoardComments < ActiveRecord::Migration[7.0]
  def change
    add_column :feedback_board_comments, :parent_id, :integer
    add_column :feedback_board_comments, :depth, :integer, default: 0, null: false

    add_index :feedback_board_comments, :parent_id
    add_foreign_key :feedback_board_comments, :feedback_board_comments, column: :parent_id

    # Update existing comments to have depth 0 (top-level comments)
    reversible do |dir|
      dir.up do
        execute "UPDATE feedback_board_comments SET depth = 0 WHERE depth IS NULL"
      end
    end
  end
end
