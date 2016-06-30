class CreatePushRegistrations < ActiveRecord::Migration
  def change
    create_table :push_registrations do |t|
      t.text :token
      t.string :device

      t.timestamps null: false
    end
  end
end
