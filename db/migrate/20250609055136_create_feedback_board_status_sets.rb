class CreateFeedbackBoardStatusSets < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_board_status_sets do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :feedback_board_status_sets, :name
    add_index :feedback_board_status_sets, :is_default

    # Create default status sets
    reversible do |dir|
      dir.up do
        now = Time.current

        # Full development lifecycle
        execute <<-SQL
          INSERT INTO feedback_board_status_sets (name, description, is_default, created_at, updated_at)
          VALUES ('Development Lifecycle', 'Full product development lifecycle with all stages', true, '#{now}', '#{now}')
        SQL

        # Simple open/closed
        execute <<-SQL
          INSERT INTO feedback_board_status_sets (name, description, is_default, created_at, updated_at)
          VALUES ('Simple Open/Closed', 'Basic open and closed statuses only', false, '#{now}', '#{now}')
        SQL

        # No statuses
        execute <<-SQL
          INSERT INTO feedback_board_status_sets (name, description, is_default, created_at, updated_at)
          VALUES ('No Status Tracking', 'Board without status tracking - just collect feedback', false, '#{now}', '#{now}')
        SQL
      end
    end
  end
end
