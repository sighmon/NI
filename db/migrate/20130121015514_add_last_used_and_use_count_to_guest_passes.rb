class AddLastUsedAndUseCountToGuestPasses < ActiveRecord::Migration
  def change
    add_column :guest_passes, :last_used, :datetime
    add_column :guest_passes, :use_count, :integer
  end
end
