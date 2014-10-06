class AddUkExpiryAndUkIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uk_expiry, :string
    add_column :users, :uk_id, :string
  end
end
