class ChangeFeaturedImageCaptionStringToTextInArticles < ActiveRecord::Migration
  def up
  	change_column :articles, :featured_image_caption, :text, limit: nil
  end

  def down
  	change_column :articles, :featured_image_caption, :string
  end
end
