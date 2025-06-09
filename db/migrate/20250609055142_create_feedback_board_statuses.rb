class CreateFeedbackBoardStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :feedback_board_statuses do |t|
      t.references :status_set, null: false, foreign_key: { to_table: :feedback_board_status_sets }
      t.string :name, null: false
      t.string :color, null: false
      t.integer :position, null: false, default: 0
      t.string :slug, null: false

      t.timestamps
    end

    add_index :feedback_board_statuses, :slug
    add_index :feedback_board_statuses, [:status_set_id, :position]
    add_index :feedback_board_statuses, [:status_set_id, :slug], unique: true

    # Create default statuses
    reversible do |dir|
      dir.up do
        now = Time.current

        # Development Lifecycle statuses
        dev_set_id = connection.select_value("SELECT id FROM feedback_board_status_sets WHERE name = 'Development Lifecycle'")
        if dev_set_id
          [
            ['Open', 'green', 0, 'open'],
            ['Planned', 'blue', 1, 'planned'],
            ['In Progress', 'yellow', 2, 'in_progress'],
            ['Complete', 'gray', 3, 'complete']
          ].each do |name, color, position, slug|
            execute <<-SQL
              INSERT INTO feedback_board_statuses (status_set_id, name, color, position, slug, created_at, updated_at)
              VALUES (#{dev_set_id}, '#{name}', '#{color}', #{position}, '#{slug}', '#{now}', '#{now}')
            SQL
          end
        end

        # Simple Open/Closed statuses
        simple_set_id = connection.select_value("SELECT id FROM feedback_board_status_sets WHERE name = 'Simple Open/Closed'")
        if simple_set_id
          [
            ['Open', 'green', 0, 'open'],
            ['Closed', 'gray', 1, 'closed']
          ].each do |name, color, position, slug|
            execute <<-SQL
              INSERT INTO feedback_board_statuses (status_set_id, name, color, position, slug, created_at, updated_at)
              VALUES (#{simple_set_id}, '#{name}', '#{color}', #{position}, '#{slug}', '#{now}', '#{now}')
            SQL
          end
        end

        # No Status Tracking has no statuses (empty set)
      end
    end
  end
end
