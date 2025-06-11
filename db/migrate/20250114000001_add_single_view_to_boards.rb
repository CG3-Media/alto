class AddSingleViewToBoards < ActiveRecord::Migration[7.0]
  def change
    add_column :alto_boards, :single_view, :string, if_not_exists: true
    add_index :alto_boards, :single_view, if_not_exists: true
  end
end
