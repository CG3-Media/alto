class UpdateFeedbackBoardTicketStatus < ActiveRecord::Migration[7.0]
  def up
    # Rename the status column to status_slug for clarity
    rename_column :feedback_board_tickets, :status, :status_slug

    # The index on [:status, :created_at] is automatically updated by SQLite
    # when the column is renamed, so we don't need to add it again
  end

  def down
    # SQLite will automatically rename the index back when we rename the column
    rename_column :feedback_board_tickets, :status_slug, :status
  end
end
