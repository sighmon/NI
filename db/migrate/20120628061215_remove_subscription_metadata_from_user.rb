class RemoveSubscriptionMetadataFromUser < ActiveRecord::Migration
  def up
  	remove_column :users, :expirydate
  	remove_column :users, :subscriber
  end

  def down
  	add_column :users, :expirydate, :datetime
  	add_column :users, :subscriber, :boolean
  end
end
