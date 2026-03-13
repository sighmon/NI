require 'rails_helper'

RSpec.describe SubscriptionCheckoutOption, type: :model do
  it 'builds a valid automatic renewal option' do
    option = described_class.from_params(duration: 12, autodebit: 1, paper: 1)

    expect(option).to be_present
    expect(option).to be_valid
    expect(option.price_cents).to eq(Subscription.calculate_subscription_price(12, autodebit: true, paper: true))
  end

  it 'rejects unsupported paper-only autodebit combinations' do
    option = described_class.from_params(duration: 12, autodebit: 1, paper_only: 1)

    expect(option).to be_nil
  end
end
