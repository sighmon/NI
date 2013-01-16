class CreateGuestPasses < ActiveRecord::Migration
  def change
    create_table :guest_passes do |t|
      t.references :user
      t.references :article
      t.string :key

      t.timestamps
    end
    add_index :guest_passes, :user_id
    add_index :guest_passes, :article_id
  end
end
