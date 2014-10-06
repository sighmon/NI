class AddUkExpiryToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uk_expiry, :datetime
  end
end
