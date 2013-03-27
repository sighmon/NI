class AddHideAuthorNameToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :hide_author_name, :boolean
  end
end
