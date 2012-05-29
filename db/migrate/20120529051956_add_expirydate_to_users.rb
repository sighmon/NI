class AddExpirydateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :expirydate, :datetime
  end
end
