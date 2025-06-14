class AddAllowVotingToAltoBoards < ActiveRecord::Migration[7.0]
  def change
    add_column :alto_boards, :allow_voting, :boolean, default: true, null: false
  end
end
