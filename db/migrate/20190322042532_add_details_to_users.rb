class AddDetailsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :title, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :company_name, :string
    add_column :users, :address, :string
    add_column :users, :postal_code, :string
    add_column :users, :city, :string
    add_column :users, :region, :string
    add_column :users, :country, :string
    add_column :users, :phone, :string
    add_column :users, :postal_mailable, :string
    add_column :users, :postal_mailable_updated, :datetime
    add_column :users, :postal_address_updated, :datetime
    add_column :users, :email_opt_in, :string
    add_column :users, :email_opt_in_updated, :datetime
    add_column :users, :email_updated, :datetime
    add_column :users, :paper_renewals, :string
    add_column :users, :digital_renewals, :string
    add_column :users, :subscriptions_order_total, :decimal
    add_column :users, :most_recent_subscriptions_order, :datetime
    add_column :users, :products_order_total, :decimal
    add_column :users, :most_recent_products_order, :datetime
    add_column :users, :annuals_buyer, :string
    add_column :users, :comments, :text
  end
end
