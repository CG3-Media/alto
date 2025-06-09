class AddItemLabelSingularToFeedbackBoardBoards < ActiveRecord::Migration[7.2]
  def change
    add_column :feedback_board_boards, :item_label_singular, :string, default: 'ticket'
  end
end
