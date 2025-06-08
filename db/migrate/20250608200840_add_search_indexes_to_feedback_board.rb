class AddSearchIndexesToFeedbackBoard < ActiveRecord::Migration[7.0]
  def change
    # Add indexes for search performance on ticket title and description
    add_index :feedback_board_tickets, :title
    add_index :feedback_board_tickets, :description, length: 255

    # Add index for search performance on comment content
    add_index :feedback_board_comments, :content, length: 255

    # Add composite index for popular search patterns
    add_index :feedback_board_tickets, [:status, :created_at]
  end
end
