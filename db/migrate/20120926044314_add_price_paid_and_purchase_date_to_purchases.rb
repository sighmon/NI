class AddPricePaidAndPurchaseDateToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :price_paid, :integer
    add_column :purchases, :purchase_date, :datetime
  end
end
