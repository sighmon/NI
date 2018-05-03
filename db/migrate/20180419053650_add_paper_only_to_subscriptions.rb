class AddPaperOnlyToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :paper_only, :boolean
  end
end
