class Rpush900GcmToFcm < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE rpush_apps
      SET type = 'Rpush::Client::ActiveRecord::Fcm::App'
      WHERE type IN (
        'Rpush::Gcm::App',
        'Rpush::Client::ActiveRecord::Gcm::App'
      )
    SQL

    execute <<~SQL.squish
      UPDATE rpush_notifications
      SET type = 'Rpush::Client::ActiveRecord::Fcm::Notification'
      WHERE type IN (
        'Rpush::Gcm::Notification',
        'Rpush::Client::ActiveRecord::Gcm::Notification'
      )
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE rpush_apps
      SET type = 'Rpush::Client::ActiveRecord::Gcm::App'
      WHERE type IN (
        'Rpush::Fcm::App',
        'Rpush::Client::ActiveRecord::Fcm::App'
      )
    SQL

    execute <<~SQL.squish
      UPDATE rpush_notifications
      SET type = 'Rpush::Client::ActiveRecord::Gcm::Notification'
      WHERE type IN (
        'Rpush::Fcm::Notification',
        'Rpush::Client::ActiveRecord::Fcm::Notification'
      )
    SQL
  end
end
