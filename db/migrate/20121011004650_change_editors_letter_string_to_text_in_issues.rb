class ChangeEditorsLetterStringToTextInIssues < ActiveRecord::Migration
  def up
  	change_column :issues, :editors_letter, :text
  end

  def down
  	change_column :issues, :editors_letter, :string
  end
end
