class AddMediaIdToImage < ActiveRecord::Migration
  def change
    add_column :images, :media_id, :integer
  end
end
