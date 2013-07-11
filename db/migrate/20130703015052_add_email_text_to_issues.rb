class AddEmailTextToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :email_text, :text
  end
end
