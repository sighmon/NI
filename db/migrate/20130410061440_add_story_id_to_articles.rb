class AddStoryIdToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :story_id, :integer
  end
end
