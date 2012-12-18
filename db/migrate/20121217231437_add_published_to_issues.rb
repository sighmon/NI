class AddPublishedToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :published, :boolean
  end
end
