require 'spec_helper'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_query'
require_relative '../../config/initializers/paypal_configuration'

RSpec.describe PaypalConfiguration do
  PAYPAL_ENV_KEYS = %w[
    PAYPAL_SANDBOX
    PAYPAL_CLIENT_ID
    PAYPAL_SECRET_KEY
    PAYPAL_CLIENT_SECRET
    PAYPAL_SECRET
    PAYPAL_WEBHOOK_ID
    PAYPAL_SANDBOX_CLIENT_ID
    PAYPAL_SANDBOX_SECRET_KEY
    PAYPAL_SANDBOX_CLIENT_SECRET
    PAYPAL_SANDBOX_SECRET
    PAYPAL_SANDBOX_WEBHOOK_ID
  ].freeze

  around do |example|
    original = PAYPAL_ENV_KEYS.each_with_object({}) do |key, values|
      values[key] = ENV.key?(key) ? ENV[key] : :__missing__
    end
    previous_sandbox = described_class.instance_variable_defined?(:@sandbox) ? described_class.instance_variable_get(:@sandbox) : :__missing__

    PAYPAL_ENV_KEYS.each { |key| ENV.delete(key) }
    described_class.remove_instance_variable(:@sandbox) if described_class.instance_variable_defined?(:@sandbox)
    example.run
  ensure
    original.each do |key, value|
      value == :__missing__ ? ENV.delete(key) : ENV[key] = value
    end
    if previous_sandbox == :__missing__
      described_class.remove_instance_variable(:@sandbox) if described_class.instance_variable_defined?(:@sandbox)
    else
      described_class.instance_variable_set(:@sandbox, previous_sandbox)
    end
  end

  it 'returns live credentials' do
    ENV['PAYPAL_SANDBOX'] = 'false'
    ENV['PAYPAL_CLIENT_ID'] = 'live-client-id'
    ENV['PAYPAL_SECRET_KEY'] = 'live-secret'

    expect(described_class.client_id).to eq('live-client-id')
    expect(described_class.secret).to eq('live-secret')
    expect(described_class.base_url).to eq('https://api-m.paypal.com')
  end

  it 'returns sandbox credentials and webhook ids' do
    ENV['PAYPAL_SANDBOX_CLIENT_ID'] = 'sandbox-client-id'
    ENV['PAYPAL_SANDBOX_SECRET_KEY'] = 'sandbox-secret'
    ENV['PAYPAL_SANDBOX_WEBHOOK_ID'] = 'sandbox-webhook'

    expect(described_class.client_id(sandbox: true)).to eq('sandbox-client-id')
    expect(described_class.secret(sandbox: true)).to eq('sandbox-secret')
    expect(described_class.webhook_id(sandbox: true)).to eq('sandbox-webhook')
  end

  it 'builds the subscription sdk url' do
    ENV['PAYPAL_CLIENT_ID'] = 'live-client-id'
    ENV['PAYPAL_SECRET_KEY'] = 'live-secret'

    sdk_url = described_class.javascript_sdk_src(sandbox: false, vault: true, intent: 'subscription')

    expect(sdk_url).to include('client-id=live-client-id')
    expect(sdk_url).to include('vault=true')
    expect(sdk_url).to include('intent=subscription')
  end

  it 'raises when credentials are missing' do
    expect {
      described_class.credentials(sandbox: false)
    }.to raise_error(PaypalConfiguration::ConfigurationError, /PAYPAL_CLIENT_ID/)
  end
end
