class RemoveExpiryDateFromSubscriptions < ActiveRecord::Migration
  def up
    remove_column :subscriptions, :expiry_date
      end

  def down
    add_column :subscriptions, :expiry_date, :datetime
  end
end
