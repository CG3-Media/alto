class AllowNullStatusSlugInTickets < ActiveRecord::Migration[7.0]
  def up
    change_column :feedback_board_tickets, :status_slug, :string, null: true, default: nil
  end

  def down
    # Set all NULL status_slug values to 'open' before making it NOT NULL again
    execute "UPDATE feedback_board_tickets SET status_slug = 'open' WHERE status_slug IS NULL"
    change_column :feedback_board_tickets, :status_slug, :string, null: false, default: 'open'
  end
end
