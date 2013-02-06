class AddPaypalCountryCodeToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :paypal_country_code, :string
  end
end
