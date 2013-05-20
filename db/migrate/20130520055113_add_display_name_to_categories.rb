class AddDisplayNameToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :display_name, :string
  end
end
