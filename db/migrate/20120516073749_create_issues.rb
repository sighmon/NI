class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :title
      t.integer :number
      t.datetime :release

      t.timestamps
    end
  end
end
