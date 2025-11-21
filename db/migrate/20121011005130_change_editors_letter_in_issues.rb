class ChangeEditorsLetterInIssues < ActiveRecord::Migration
  def up
  	change_column :issues, :editors_letter, :text, limit: nil
  end

  def down
  	change_column :issues, :editors_letter, :text
  end
end
