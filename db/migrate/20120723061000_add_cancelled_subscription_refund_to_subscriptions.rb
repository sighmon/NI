class AddCancelledSubscriptionRefundToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :refund, :integer
  end
end
