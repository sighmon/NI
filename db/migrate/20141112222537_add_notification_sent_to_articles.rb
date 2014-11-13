class AddNotificationSentToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :notification_sent, :datetime
  end
end
