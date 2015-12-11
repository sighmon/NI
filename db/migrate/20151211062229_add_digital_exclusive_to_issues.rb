class AddDigitalExclusiveToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :digital_exclusive, :boolean
  end
end
