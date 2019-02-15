class AddManagerToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :manager, :boolean
  end
end
