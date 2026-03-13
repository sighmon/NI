require 'rails_helper'

RSpec.describe PaymentNotificationsController, type: :controller do
  let(:payload) do
    {
      id: 'WH-123',
      event_type: 'PAYMENT.SALE.COMPLETED',
      resource: {
        id: 'SALE-123',
        billing_agreement_id: 'I-SUBSCRIPTION',
        amount: { value: '50.00', currency_code: 'AUD' }
      }
    }
  end

  it 'verifies and processes a webhook' do
    verifier = instance_double(PaypalRest::WebhookVerifier, valid?: true)
    handler = instance_double(PaypalRest::WebhookHandler, process!: true)

    allow(PaypalRest::WebhookVerifier).to receive(:new).and_return(verifier)
    allow(PaypalRest::WebhookHandler).to receive(:new).and_return(handler)
    request.headers['CONTENT_TYPE'] = 'application/json'
    allow(request).to receive(:raw_post).and_return(payload.to_json)

    post :create, body: payload.to_json, format: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq('success' => true)
  end
end
