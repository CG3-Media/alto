class UpdateFeedbackBoardTicketStatus < ActiveRecord::Migration[7.2]
  def change
    # Rename the status column to status_slug for clarity
    rename_column :feedback_board_tickets, :status, :status_slug

    # Remove the old status indexes if they exist (with different names)
    remove_index :feedback_board_tickets, name: "index_feedback_board_tickets_on_status", if_exists: true
    remove_index :feedback_board_tickets, name: "index_feedback_board_tickets_on_status_and_created_at", if_exists: true

    # Add the composite index with new column name (individual index should already exist from rename)
    add_index :feedback_board_tickets, [:status_slug, :created_at], if_not_exists: true
  end
end
