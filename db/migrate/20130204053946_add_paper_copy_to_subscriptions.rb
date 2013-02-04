class AddPaperCopyToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :paper_copy, :boolean
  end
end
