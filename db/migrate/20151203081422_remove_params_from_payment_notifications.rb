class RemoveParamsFromPaymentNotifications < ActiveRecord::Migration
  def change
    remove_column :payment_notifications, :params, :text
  end
end
