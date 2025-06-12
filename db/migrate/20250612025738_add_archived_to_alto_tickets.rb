class AddArchivedToAltoTickets < ActiveRecord::Migration[7.2]
  def change
    add_column :alto_tickets, :archived, :boolean, default: false, null: false
    add_index :alto_tickets, :archived, if_not_exists: true
  end
end
