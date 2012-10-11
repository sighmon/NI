class ChangeTeaserTextLimitInArticles < ActiveRecord::Migration
  def up
  	change_column :articles, :teaser, :text, :limit => nil
  end

  def down
  end
end
