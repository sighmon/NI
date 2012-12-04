class CreateFavourites < ActiveRecord::Migration
  def change
    create_table :favourites do |t|
      t.integer :user_id
      t.integer :article_id
      t.integer :issue_id
      t.datetime :created_at

      t.timestamps
    end
  end
end
