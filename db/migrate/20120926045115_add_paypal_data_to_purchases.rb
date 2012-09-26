class AddPaypalDataToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :paypal_payer_id, :string
    add_column :purchases, :paypal_first_name, :string
    add_column :purchases, :paypal_last_name, :string
  end
end
