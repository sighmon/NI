class RemoveCategoryFromArticles < ActiveRecord::Migration
  def up
    remove_column :articles, :category
  end

  def down
    add_column :articles, :category, :string
  end
end
