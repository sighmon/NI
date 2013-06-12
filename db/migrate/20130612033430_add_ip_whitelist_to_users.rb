class AddIpWhitelistToUsers < ActiveRecord::Migration
  def change
    add_column :users, :ip_whitelist, :string
  end
end
