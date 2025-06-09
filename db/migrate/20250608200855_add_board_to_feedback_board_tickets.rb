class AddBoardToFeedbackBoardTickets < ActiveRecord::Migration[7.0]
  def change
    # Add board_id column to tickets
    add_column :feedback_board_tickets, :board_id, :integer, null: true

    # Add index for performance
    add_index :feedback_board_tickets, :board_id

        # Migrate existing tickets to the default board
    reversible do |dir|
      dir.up do
        # Use ActiveRecord for database-agnostic operations
        default_board = ::FeedbackBoard::Board.find_by(slug: 'feedback')
        if default_board
          ::FeedbackBoard::Ticket.where(board_id: nil).update_all(board_id: default_board.id)
        end
      end
    end

    # Make board_id required after data migration
    change_column_null :feedback_board_tickets, :board_id, false

    # Add foreign key constraint
    add_foreign_key :feedback_board_tickets, :feedback_board_boards, column: :board_id
  end
end
