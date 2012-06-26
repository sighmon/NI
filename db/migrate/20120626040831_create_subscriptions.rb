class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :user
      t.integer :user_id
      t.datetime :expiry_date

      t.timestamps
    end
  end
end
