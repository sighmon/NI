class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.text :teaser
      t.string :author
      t.datetime :publication
      t.text :body
      t.references :issue

      t.timestamps
    end
    add_index :articles, :issue_id
  end
end
