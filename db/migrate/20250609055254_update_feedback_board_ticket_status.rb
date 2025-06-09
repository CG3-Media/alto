class UpdateFeedbackBoardTicketStatus < ActiveRecord::Migration[7.0]
  def up
    # Rename the status column to status_slug for clarity
    rename_column :feedback_board_tickets, :status, :status_slug

    # Add the composite index with new column name
    add_index :feedback_board_tickets, [:status_slug, :created_at]
  end

  def down
    # Not needed since we're in dev mode, but here for completeness
    remove_index :feedback_board_tickets, [:status_slug, :created_at]
    rename_column :feedback_board_tickets, :status_slug, :status
  end
end
