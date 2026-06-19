require 'rails_helper'

describe "admin/push_notifications/index.html.erb", type: :view do
  let(:common_attributes) do
    {
      delivered: false,
      failed: false,
      deliver_after: nil,
      delivered_at: nil,
      failed_at: nil,
      error_description: nil,
      updated_at: Time.zone.parse("2026-06-19 03:21:24"),
      data: { "body" => "Test notification" }
    }
  end

  let(:android_notification) do
    double(
      "Android notification",
      **common_attributes,
      id: 1,
      type: "Rpush::Client::ActiveRecord::Fcm::Notification",
      device_token: "android-device-token-12345678",
      registration_ids: nil
    )
  end

  let(:ios_notification) do
    double(
      "iOS notification",
      **common_attributes,
      id: 2,
      type: "Rpush::Client::ActiveRecord::Apnsp8::Notification",
      device_token: "ios-device-token-12345678",
      registration_ids: nil
    )
  end

  let(:legacy_android_notification) do
    double(
      "Legacy Android notification",
      **common_attributes,
      id: 3,
      type: "Rpush::Gcm::Notification",
      device_token: nil,
      registration_ids: [nil, "legacy-android-token-12345678"]
    )
  end

  before do
    assign(:pn_total, 3)
    assign(:pn_undelivered, 3)
    assign(:pagy, double("Pagy"))
    assign(
      :push_notifications,
      [android_notification, ios_notification, legacy_android_notification]
    )
    allow(view).to receive(:pagy_bootstrap_nav).and_return("PAGY NAV")

    render template: "admin/push_notifications/index"
  end

  it "labels FCM notifications as Android when their token is stored in device_token" do
    expect(rendered).to include("Android:")
    expect(rendered).to include("android-...12345678")
  end

  it "continues to label APNs notifications as iOS" do
    expect(rendered).to include("iOS:")
    expect(rendered).to include("ios-devi...12345678")
  end

  it "skips nil legacy registration IDs" do
    expect(rendered).to include("legacy-a...12345678")
  end
end
