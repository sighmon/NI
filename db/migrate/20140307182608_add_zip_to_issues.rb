class AddZipToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :zip, :string
  end
end
