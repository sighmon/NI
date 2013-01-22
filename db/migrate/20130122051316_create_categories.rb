class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.references :article
      t.string :name

      t.timestamps
    end
    add_index :categories, :article_id
  end
end
