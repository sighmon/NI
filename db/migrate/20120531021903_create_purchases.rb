class CreatePurchases < ActiveRecord::Migration
  def change
    create_table :purchases do |t|
      t.integer :user_id
      t.integer :issue_id
      t.datetime :created_at

      t.timestamps
    end
  end
end
