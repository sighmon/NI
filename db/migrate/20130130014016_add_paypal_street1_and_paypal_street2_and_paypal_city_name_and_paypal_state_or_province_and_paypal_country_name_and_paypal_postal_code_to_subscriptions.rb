class AddPaypalStreet1AndPaypalStreet2AndPaypalCityNameAndPaypalStateOrProvinceAndPaypalCountryNameAndPaypalPostalCodeToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :paypal_street1, :string
    add_column :subscriptions, :paypal_street2, :string
    add_column :subscriptions, :paypal_city_name, :string
    add_column :subscriptions, :paypal_state_or_province, :string
    add_column :subscriptions, :paypal_country_name, :string
    add_column :subscriptions, :paypal_postal_code, :string
  end
end
