class AddTeaserToPages < ActiveRecord::Migration
  def change
    add_column :pages, :teaser, :text
  end
end
