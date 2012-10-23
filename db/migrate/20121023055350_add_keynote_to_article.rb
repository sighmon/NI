class AddKeynoteToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :keynote, :boolean
  end
end
