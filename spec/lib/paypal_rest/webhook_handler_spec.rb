require 'rails_helper'

RSpec.describe PaypalRest::WebhookHandler do
  describe '#process!' do
    it 'creates a renewal subscription from a completed sale webhook' do
      existing_subscription = FactoryBot.create(
        :subscription,
        paypal_profile_id: 'I-SUBSCRIPTION',
        duration: 12,
        price_paid: 5000
      )
      user = existing_subscription.user

      event = {
        'id' => 'WH-123',
        'event_type' => 'PAYMENT.SALE.COMPLETED',
        'resource' => {
          'id' => 'SALE-123',
          'billing_agreement_id' => 'I-SUBSCRIPTION',
          'amount' => { 'value' => '50.00', 'currency_code' => 'AUD' }
        }
      }

      expect {
        described_class.new(event: event).process!
      }.to change(Subscription, :count).by(1)
        .and change(PaymentNotification, :count).by(1)

      renewal = user.subscriptions.order(:created_at).last
      expect(renewal.paypal_profile_id).to eq('I-SUBSCRIPTION')
      expect(renewal.price_paid).to eq(5000)
    end
  end
end
