require 'rails_helper'

RSpec.describe PurchasesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:issue) { FactoryBot.create(:issue) }
  let(:paypal_client) { instance_double(PaypalRest::Client) }

  before do
    sign_in user
    allow(PaypalRest::Client).to receive(:new).and_return(paypal_client)
  end

  describe 'POST paypal_order' do
    it 'creates a paypal order' do
      allow(paypal_client).to receive(:create_order).and_return({ 'id' => 'ORDER-123' })

      post :paypal_order, params: { issue_id: issue.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('id' => 'ORDER-123')
    end
  end

  describe 'POST create' do
    it 'captures an order and creates a purchase' do
      allow(paypal_client).to receive(:capture_order).and_return(
        {
          'status' => 'COMPLETED',
          'payer' => {
            'payer_id' => 'PAYER-123',
            'email_address' => user.email,
            'name' => { 'given_name' => 'Jane', 'surname' => 'Reader' }
          }
        }
      )

      expect {
        post :create, params: { issue_id: issue.id, paypal_order_id: 'ORDER-123' }, format: :json
      }.to change(Purchase, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Purchase.last.paypal_payer_id).to eq('PAYER-123')
    end
  end
end
