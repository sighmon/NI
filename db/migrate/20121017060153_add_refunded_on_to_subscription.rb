class AddRefundedOnToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :refunded_on, :datetime
  end
end
