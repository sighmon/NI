class AddPaypalDataToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :paypal_payer_id, :string
    add_column :subscriptions, :paypal_profile_id, :string
    add_column :subscriptions, :paypal_first_name, :string
    add_column :subscriptions, :paypal_last_name, :string
  end
end
