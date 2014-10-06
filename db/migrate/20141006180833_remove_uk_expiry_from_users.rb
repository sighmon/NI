class RemoveUkExpiryFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :uk_expiry
  end

  def down
    add_column :users, :uk_expiry, :string
  end
end
