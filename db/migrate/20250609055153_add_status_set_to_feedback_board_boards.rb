class AddStatusSetToFeedbackBoardBoards < ActiveRecord::Migration[7.0]
  def change
    add_reference :feedback_board_boards, :status_set, null: true, foreign_key: { to_table: :feedback_board_status_sets }

    # Assign the default status set to existing boards
    reversible do |dir|
      dir.up do
        default_status_set_id = connection.select_value("SELECT id FROM feedback_board_status_sets WHERE is_default = true LIMIT 1")
        if default_status_set_id
          execute <<-SQL
            UPDATE feedback_board_boards
            SET status_set_id = #{default_status_set_id}
            WHERE status_set_id IS NULL
          SQL
        end
      end
    end
  end
end
