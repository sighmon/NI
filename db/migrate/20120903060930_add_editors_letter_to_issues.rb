class AddEditorsLetterToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :editors_letter, :string
  end
end
