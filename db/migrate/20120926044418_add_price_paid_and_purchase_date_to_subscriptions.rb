class AddPricePaidAndPurchaseDateToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :price_paid, :integer
    add_column :subscriptions, :purchase_date, :datetime
  end
end
