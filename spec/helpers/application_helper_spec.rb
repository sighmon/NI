require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '.rpush_register_android_app' do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      allow(ENV).to receive(:fetch).with('RPUSH_ANDROID_DEVELOPMENT_APP_NAME').and_return('android-dev')
      allow(ENV).to receive(:fetch).with('ANDROID_DEVELOPMENT_FIREBASE_PROJECT_ID').and_return('firebase-dev')
      allow(ENV).to receive(:fetch).with('ANDROID_DEVELOPMENT_JSON_KEY').and_return('{"client_email":"firebase@example.com"}')
    end

    it 'creates an FCM app with Firebase service account settings' do
      described_class.rpush_register_android_app

      app = Rpush::Fcm::App.find_by!(name: 'android-dev')
      expect(app.type).to eq('Rpush::Client::ActiveRecord::Fcm::App')
      expect(app.environment).to eq('sandbox')
      expect(app.firebase_project_id).to eq('firebase-dev')
      expect(app.json_key).to eq('{"client_email":"firebase@example.com"}')
      expect(app.connections).to eq(1)
    end

    it 'converts removed GCM STI records to FCM without instantiating them' do
      legacy_app = Rpush::Client::ActiveRecord::Apns::App.new(
        name: 'android-dev',
        environment: 'sandbox'
      )
      legacy_app.save!(validate: false)
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(
        app: legacy_app,
        registration_ids: %w[legacy-token-one legacy-token-two],
        data: { message: 'Test' },
        deliver_after: Time.zone.parse('2026-06-20 10:00')
      )
      notification.save!(validate: false)
      legacy_app_id = legacy_app.id
      notification_id = notification.id

      Rpush::Client::ActiveRecord::App
        .where(id: legacy_app_id)
        .update_all(type: 'Rpush::Gcm::App')
      Rpush::Client::ActiveRecord::Notification
        .where(id: notification_id)
        .update_all(type: 'Rpush::Gcm::Notification')

      current_app = described_class.rpush_register_android_app

      notifications = Rpush::Fcm::Notification.where(app_id: current_app.id).order(:id)
      expect(notifications.pluck(:device_token)).to eq(%w[legacy-token-one legacy-token-two])
      expect(notifications.pluck(:registration_ids)).to eq([nil, nil])
      expect(notifications.map(&:data)).to eq([{ 'message' => 'Test' }, { 'message' => 'Test' }])
      expect(notifications.pluck(:deliver_after)).to all(eq(Time.zone.parse('2026-06-20 10:00')))
      expect(notifications.first.id).to eq(notification_id)
      expect(Rpush::Client::ActiveRecord::App.where(id: legacy_app_id)).not_to exist
    end

    it 'converts queued recipients already attached to the migrated FCM app' do
      app = Rpush::Fcm::App.create!(
        name: 'android-dev',
        environment: 'sandbox',
        firebase_project_id: 'old-project',
        json_key: '{"client_email":"old@example.com"}'
      )
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(
        app: app,
        registration_ids: %w[current-token-one current-token-two],
        data: { message: 'Queued before upgrade' }
      )
      notification.save!(validate: false)
      Rpush::Client::ActiveRecord::Notification
        .where(id: notification.id)
        .update_all(type: Rpush::Fcm::Notification.name)

      current_app = described_class.rpush_register_android_app

      expect(current_app.id).to eq(app.id)
      notifications = Rpush::Fcm::Notification.where(app_id: current_app.id).order(:id)
      expect(notifications.pluck(:device_token)).to eq(%w[current-token-one current-token-two])
      expect(notifications.pluck(:registration_ids)).to eq([nil, nil])
      expect(notifications.map(&:data)).to all(eq('message' => 'Queued before upgrade'))
    end

    it 'defers conversion while a migrated FCM notification is processing' do
      app = Rpush::Fcm::App.create!(
        name: 'android-dev',
        environment: 'sandbox',
        firebase_project_id: 'old-project',
        json_key: '{"client_email":"old@example.com"}'
      )
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(
        app: app,
        registration_ids: %w[active-token-one active-token-two],
        data: { message: 'In flight' },
        processing: true
      )
      notification.save!(validate: false)
      Rpush::Client::ActiveRecord::Notification
        .where(id: notification.id)
        .update_all(type: Rpush::Fcm::Notification.name)

      described_class.rpush_register_android_app

      in_flight = Rpush::Client::ActiveRecord::Notification.where(app_id: app.id)
      expect(in_flight.count).to eq(1)
      expect(in_flight.pick(:device_token, :processing)).to eq([nil, true])
      expect(in_flight.first.registration_ids).to eq(%w[active-token-one active-token-two])

      in_flight.update_all(processing: false)
      described_class.rpush_register_android_app

      converted = Rpush::Fcm::Notification.where(app_id: app.id).order(:id)
      expect(converted.pluck(:device_token)).to eq(%w[active-token-one active-token-two])
      expect(converted.pluck(:processing)).to eq([false, false])
    end

    it 'moves a processing notification off an unsupported legacy app without splitting it' do
      legacy_app = Rpush::Client::ActiveRecord::Apns::App.new(
        name: 'android-dev',
        environment: 'sandbox'
      )
      legacy_app.save!(validate: false)
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(
        app: legacy_app,
        registration_ids: %w[active-legacy-one active-legacy-two],
        processing: true
      )
      notification.save!(validate: false)
      Rpush::Client::ActiveRecord::App
        .where(id: legacy_app.id)
        .update_all(type: 'Rpush::Gcm::App')
      Rpush::Client::ActiveRecord::Notification
        .where(id: notification.id)
        .update_all(type: 'Rpush::Gcm::Notification')

      current_app = described_class.rpush_register_android_app

      expect(Rpush::Client::ActiveRecord::App.where(id: legacy_app.id)).not_to exist
      values = Rpush::Client::ActiveRecord::Notification
        .where(id: notification.id)
        .pick(:app_id, :type, :device_token, :processing)
      expect(values).to eq(
        [current_app.id, Rpush::Fcm::Notification.name, nil, true]
      )
      expect(
        Rpush::Client::ActiveRecord::Notification.where(app_id: current_app.id).count
      ).to eq(1)
      expect(
        Rpush::Client::ActiveRecord::Notification.find(notification.id).registration_ids
      ).to eq(%w[active-legacy-one active-legacy-two])
    end

    it 'does not consolidate a same-name app from another push service or environment' do
      ios_app = Rpush::Apnsp8::App.new(name: 'android-dev', environment: 'sandbox')
      ios_app.save!(validate: false)
      ios_notification = Rpush::Apnsp8::Notification.new(
        app: ios_app,
        device_token: 'ios-token',
        alert: 'iOS message'
      )
      ios_notification.save!(validate: false)

      production_gcm_app = Rpush::Client::ActiveRecord::Apns::App.new(
        name: 'android-dev',
        environment: 'production'
      )
      production_gcm_app.save!(validate: false)
      Rpush::Client::ActiveRecord::App
        .where(id: production_gcm_app.id)
        .update_all(type: 'Rpush::Gcm::App')

      described_class.rpush_register_android_app

      expect(Rpush::Client::ActiveRecord::App.where(id: ios_app.id)).to exist
      expect(ios_notification.reload.app_id).to eq(ios_app.id)
      expect(ios_notification.type).to eq('Rpush::Client::ActiveRecord::Apnsp8::Notification')
      expect(Rpush::Client::ActiveRecord::App.where(id: production_gcm_app.id)).to exist
    end
  end

  describe '.rpush_create_android_push_notification' do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      allow(ENV).to receive(:fetch).with('RPUSH_ANDROID_DEVELOPMENT_APP_NAME').and_return('android-dev')

      Rpush::Fcm::App.create!(
        name: 'android-dev',
        environment: 'sandbox',
        firebase_project_id: 'firebase-dev',
        json_key: '{"client_email":"firebase@example.com"}'
      )
    end

    it 'creates one FCM notification per Android token' do
      notifications = described_class.rpush_create_android_push_notification(
        %w[token-one token-two],
        {
          body: 'Test message.',
          deliver_after: Time.zone.parse('2026-05-22 10:00'),
          railsID: '123'
        }
      )

      expect(notifications.size).to eq(2)
      expect(notifications.map(&:type).uniq).to eq(['Rpush::Client::ActiveRecord::Fcm::Notification'])
      expect(notifications.map(&:device_token)).to eq(%w[token-one token-two])
      expect(notifications.map(&:registration_ids)).to all(be_nil)
      expect(notifications.first.notification).to include('body' => 'Test message.', 'icon' => 'ni_notification')
      expect(notifications.first.data).to include('body' => 'Test message.', 'railsID' => '123')
      expect(notifications.first.uri).to eq('newint://issues/123')
    end
  end

  describe '.rpush_send_notifications' do
    let(:app) do
      Rpush::Fcm::App.create!(
        name: 'android-dev',
        environment: 'sandbox',
        firebase_project_id: 'firebase-dev',
        json_key: '{"client_email":"firebase@example.com"}'
      )
    end

    before do
      allow(described_class).to receive(:rpush_prepare_apps)
    end

    it 'does not reclaim processing notifications owned by another runner' do
      notification = Rpush::Fcm::Notification.create!(
        app: app,
        device_token: 'android-token',
        notification: { body: 'Test' },
        processing: true,
        updated_at: 10.minutes.ago
      )

      allow(Rpush).to receive(:push)

      result = described_class.rpush_send_notifications

      expect(Rpush).not_to have_received(:push)
      expect(result).to eq(attempted: 0, delivered: 0, failed: 0, pending: 0)
      expect(notification.reload.processing).to be(true)
    end

    it 'does not clear processing state set by a concurrent runner' do
      notification = Rpush::Fcm::Notification.create!(
        app: app,
        device_token: 'android-token',
        notification: { body: 'Test' }
      )
      allow(Rpush).to receive(:push) do
        notification.update!(processing: true)
      end

      result = described_class.rpush_send_notifications

      expect(result).to eq(attempted: 1, delivered: 0, failed: 0, pending: 1)
      expect(notification.reload.processing).to be(true)
    end
  end

  describe '.start_delayed_jobs' do
    let(:dyno_client) { instance_double('DynoClient') }
    let(:platform_client) { instance_double('PlatformClient', dyno: dyno_client) }

    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      allow(ENV).to receive(:fetch).with('HEROKU_OAUTH').and_return('oauth-token')
      allow(ENV).to receive(:fetch).with('HEROKU_OAUTH_APP_NAME').and_return('ni-production')
      allow(PlatformAPI).to receive(:connect_oauth).with('oauth-token').and_return(platform_client)
    end

    it 'passes the dyno size through for one-off workers' do
      expect(dyno_client).to receive(:create) do |app_name, options|
        expect(app_name).to eq('ni-production')
        expect(options).to eq(
          command: 'bundle exec bin/delayed_job run --exit-on-complete',
          size: 'standard-2x'
        )
      end

      described_class.start_delayed_jobs(size: 'standard-2x')
    end

    it 'keeps the existing command when no dyno size is requested' do
      expect(dyno_client).to receive(:create) do |app_name, options|
        expect(app_name).to eq('ni-production')
        expect(options).to eq(
          command: 'bundle exec bin/delayed_job run --exit-on-complete'
        )
      end

      described_class.start_delayed_jobs
    end
  end
end
