class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.datetime :expiry_date
      t.references :user

      t.timestamps
    end
    add_index :subscriptions, :user_id
  end
end
