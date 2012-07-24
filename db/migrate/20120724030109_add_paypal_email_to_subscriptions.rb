class AddPaypalEmailToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :paypal_email, :string
  end
end
