class CreateArticleCategorisations < ActiveRecord::Migration
  def change
    create_table :article_categorisations do |t|
      t.references :article
      t.references :category
      t.integer :position

      t.timestamps
    end
  end
end
