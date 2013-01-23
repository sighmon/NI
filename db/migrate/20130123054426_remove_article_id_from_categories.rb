class RemoveArticleIdFromCategories < ActiveRecord::Migration
  def up
    remove_column :categories, :article_id
  end

  def down
    add_column :categories, :article_id, :integer
  end
end
