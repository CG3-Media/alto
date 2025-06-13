class AddViewableByPublicToAltoStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :alto_statuses, :viewable_by_public, :boolean, default: true, null: false
  end
end
