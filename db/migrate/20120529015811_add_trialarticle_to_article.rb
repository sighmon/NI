class AddTrialarticleToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :trialarticle, :boolean
  end
end
