class AddEditorsNameAndEditorsPhotoToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :editors_name, :string
    add_column :issues, :editors_photo, :string
  end
end
