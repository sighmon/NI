class AddInstitutionFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :institution, :boolean
    add_column :users, :parent_id, :integer
  end
end
