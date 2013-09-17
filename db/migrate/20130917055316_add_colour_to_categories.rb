class AddColourToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :colour, :int
  end
end
