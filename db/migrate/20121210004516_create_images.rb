class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :data
      t.references :article

      t.timestamps
    end
    add_index :images, :article_id
  end
end
