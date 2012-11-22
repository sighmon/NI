class AddFeaturedImageAndFeaturedImageCaptionToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :featured_image, :string
    add_column :articles, :featured_image_caption, :string
  end
end
