class AddAllowPublicTaggingToAltoBoards < ActiveRecord::Migration[7.0]
  def change
    add_column :alto_boards, :allow_public_tagging, :boolean, default: false, null: false
  end
end