class CreateFeedbackBoardBoards < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_board_boards do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    # Add indexes for performance
    add_index :feedback_board_boards, :slug, unique: true
    add_index :feedback_board_boards, :name

    # Create the default "Feedback" board
    reversible do |dir|
      dir.up do
        # Use Ruby's Time.current for database compatibility
        now = Time.current
        execute <<-SQL
          INSERT INTO feedback_board_boards (name, slug, description, item_label_singular, created_at, updated_at)
          VALUES ('Feedback', 'feedback', 'General feedback and feature requests', 'ticket', '#{now}', '#{now}')
        SQL
      end
    end
  end
end
