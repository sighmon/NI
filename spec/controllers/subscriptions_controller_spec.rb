require 'rails_helper'

RSpec.describe SubscriptionsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:paypal_client) { instance_double(PaypalRest::Client) }

  before do
    sign_in user
    allow(PaypalRest::Client).to receive(:new).and_return(paypal_client)
  end

  describe 'POST create' do
    it 'creates a once-off subscription from a captured order' do
      allow(paypal_client).to receive(:capture_order).and_return(
        {
          'status' => 'COMPLETED',
          'payer' => {
            'payer_id' => 'PAYER-123',
            'email_address' => user.email,
            'name' => { 'given_name' => 'Jane', 'surname' => 'Reader' }
          },
          'purchase_units' => [{ 'shipping' => { 'address' => { 'country_code' => 'AU' } } }]
        }
      )

      expect {
        post :create, params: { duration: 12, autodebit: 0, paypal_order_id: 'ORDER-123' }, format: :json
      }.to change(Subscription, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Subscription.last.price_paid).to eq(Subscription.calculate_subscription_price(12, autodebit: false))
    end
  end

  describe 'POST paypal_subscription_approval' do
    it 'creates an automatic renewal subscription from paypal subscription details' do
      allow(paypal_client).to receive(:show_subscription).and_return(
        {
          'id' => 'I-SUBSCRIPTION',
          'subscriber' => {
            'payer_id' => 'PAYER-456',
            'email_address' => user.email,
            'name' => { 'given_name' => 'Sam', 'surname' => 'Subscriber' },
            'shipping_address' => {
              'name' => { 'full_name' => 'Sam Subscriber' },
              'address' => {
                'address_line_1' => '1 Main St',
                'admin_area_2' => 'Adelaide',
                'admin_area_1' => 'SA',
                'postal_code' => '5000',
                'country_code' => 'AU'
              }
            }
          }
        }
      )

      expect {
        post :paypal_subscription_approval, params: { duration: 12, autodebit: 1, paypal_subscription_id: 'I-SUBSCRIPTION' }, format: :json
      }.to change(Subscription, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Subscription.last.paypal_profile_id).to eq('I-SUBSCRIPTION')
    end
  end
end
