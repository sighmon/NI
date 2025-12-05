class ChangeBodyTextLimitInArticles < ActiveRecord::Migration
  def up
  	change_column :articles, :body, :text, limit: nil
  end

  def down
  end
end
