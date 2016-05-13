class AddUnpublishedToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :unpublished, :boolean
  end
end
