class AddHiddenToImages < ActiveRecord::Migration
  def change
    add_column :images, :hidden, :boolean
  end
end
