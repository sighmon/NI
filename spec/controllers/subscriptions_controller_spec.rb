require 'rails_helper'

RSpec.describe SubscriptionsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:paypal_client) { instance_double(PaypalRest::Client) }
  let(:plan_catalog) { instance_double(PaypalRest::PlanCatalog) }
  let(:once_off_twelve_month_price) { format('%.2f', Subscription.calculate_subscription_price(12, autodebit: false) / 100.0) }
  let(:once_off_three_month_price) { format('%.2f', Subscription.calculate_subscription_price(3, autodebit: false) / 100.0) }

  before do
    sign_in user
    allow(PaypalRest::Client).to receive(:new).and_return(paypal_client)
    allow(PaypalRest::PlanCatalog).to receive(:new).and_return(plan_catalog)
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
          'purchase_units' => [
            {
              'custom_id' => "subscription-12_once_digital_individual_standard-user-#{user.id}",
              'amount' => { 'currency_code' => 'AUD', 'value' => once_off_twelve_month_price },
              'shipping' => { 'address' => { 'country_code' => 'AU' } },
              'payments' => {
                'captures' => [
                  {
                    'status' => 'COMPLETED',
                    'amount' => { 'currency_code' => 'AUD', 'value' => once_off_twelve_month_price }
                  }
                ]
              }
            }
          ]
        }
      )

      expect {
        post :create, params: { duration: 12, autodebit: 0, paypal_order_id: 'ORDER-123' }, format: :json
      }.to change(Subscription, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Subscription.last.price_paid).to eq(Subscription.calculate_subscription_price(12, autodebit: false))
    end

    it 'rejects a captured order that does not match the selected option' do
      allow(paypal_client).to receive(:capture_order).and_return(
        {
          'status' => 'COMPLETED',
          'purchase_units' => [
            {
              'custom_id' => "subscription-3_once_digital_individual_standard-user-#{user.id}",
              'amount' => { 'currency_code' => 'AUD', 'value' => once_off_three_month_price }
            }
          ]
        }
      )

      expect {
        post :create, params: { duration: 12, autodebit: 0, paypal_order_id: 'ORDER-123' }, format: :json
      }.not_to change(Subscription, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'PayPal order did not match the selected subscription.')
    end
  end

  describe 'POST paypal_subscription_approval' do
    it 'creates an automatic renewal subscription from paypal subscription details' do
      allow(plan_catalog).to receive(:ensure_plan!).and_return({ 'id' => 'P-12-AUTODEBIT' })
      allow(paypal_client).to receive(:show_subscription).and_return(
        {
          'id' => 'I-SUBSCRIPTION',
          'plan_id' => 'P-12-AUTODEBIT',
          'custom_id' => "subscription-12_autodebit_digital_individual_standard-user-#{user.id}",
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

    it 'rejects an approved subscription for a different plan' do
      allow(plan_catalog).to receive(:ensure_plan!).and_return({ 'id' => 'P-12-AUTODEBIT' })
      allow(paypal_client).to receive(:show_subscription).and_return(
        {
          'id' => 'I-SUBSCRIPTION',
          'plan_id' => 'P-3-AUTODEBIT',
          'custom_id' => "subscription-12_autodebit_digital_individual_standard-user-#{user.id}",
          'subscriber' => {
            'payer_id' => 'PAYER-456',
            'email_address' => user.email
          }
        }
      )

      expect {
        post :paypal_subscription_approval, params: { duration: 12, autodebit: 1, paypal_subscription_id: 'I-SUBSCRIPTION' }, format: :json
      }.not_to change(Subscription, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'PayPal subscription did not match the selected subscription.')
    end

    it 'rejects an approved subscription for a different user selection' do
      allow(plan_catalog).to receive(:ensure_plan!).and_return({ 'id' => 'P-12-AUTODEBIT' })
      allow(paypal_client).to receive(:show_subscription).and_return(
        {
          'id' => 'I-SUBSCRIPTION',
          'plan_id' => 'P-12-AUTODEBIT',
          'custom_id' => 'subscription-3_autodebit_digital_individual_standard-user-999',
          'subscriber' => {
            'payer_id' => 'PAYER-456',
            'email_address' => user.email
          }
        }
      )

      expect {
        post :paypal_subscription_approval, params: { duration: 12, autodebit: 1, paypal_subscription_id: 'I-SUBSCRIPTION' }, format: :json
      }.not_to change(Subscription, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'PayPal subscription did not match the selected subscription.')
    end
  end
end
