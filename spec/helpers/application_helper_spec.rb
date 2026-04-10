require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
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
