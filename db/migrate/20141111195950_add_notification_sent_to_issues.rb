class AddNotificationSentToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :notification_sent, :datetime
  end
end
