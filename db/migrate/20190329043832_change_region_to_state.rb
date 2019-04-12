class ChangeRegionToState < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :region, :state
  end
end
