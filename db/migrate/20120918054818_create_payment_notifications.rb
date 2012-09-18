class CreatePaymentNotifications < ActiveRecord::Migration
  def change
    create_table :payment_notifications do |t|
      t.text :params
      t.string :status
      t.string :transaction_id
      t.string :transaction_type
      t.integer :user_id

      t.timestamps
    end
  end
end
