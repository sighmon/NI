class AddHeightAndWidthToImage < ActiveRecord::Migration
  def change
    add_column :images, :height, :integer
    add_column :images, :width, :integer
  end
end
