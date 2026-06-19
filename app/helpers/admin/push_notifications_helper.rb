module Admin::PushNotificationsHelper
  def android_push_notification?(notification)
    notification.type.to_s.match?(/::(?:Fcm|Gcm)::Notification\z/) ||
      (notification.device_token.blank? && notification.registration_ids.present?)
  end

  def push_notification_device_tokens(notification)
    if android_push_notification?(notification)
      Array(notification.device_token.presence || notification.registration_ids).compact
    else
      Array(notification.device_token).compact
    end
  end
end
