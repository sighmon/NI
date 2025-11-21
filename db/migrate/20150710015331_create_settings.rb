class CreateSettings < ActiveRecord::Migration

  def change
    rename_column :settings, :target_id, :thing_id
    rename_column :settings, :target_type, :thing_type
    change_column :settings, :thing_id, :integer, null: true
    change_column :settings, :thing_type, :string, null: true
    change_column :settings, :value, :text, null: true
  end

end
