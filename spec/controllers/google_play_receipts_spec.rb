require 'rails_helper'
require 'google/apis/errors'

RSpec.describe IssuesController, type: :controller do
  before do
    allow_any_instance_of(Issue).to receive(:index_document)
    allow_any_instance_of(Article).to receive(:index_document)
    allow_any_instance_of(Article).to receive(:update_document)
    allow_any_instance_of(Article).to receive(:delete_document)
  end

  describe 'POST show' do
    let(:issue) { FactoryBot.create(:published_issue) }
    let(:purchase) { instance_double(Services::GooglePlayVerification) }
    let(:receipt_json) do
      [{ productId: "#{issue.number}single", purchaseToken: 'bad-token' }].to_json
    end

    before do
      request.headers['CONTENT_TYPE'] = 'application/json'
      allow(controller.request).to receive(:raw_post).and_return(receipt_json)
      allow(Services::GooglePlayVerification).to receive(:new).and_return(purchase)
      allow(purchase).to receive(:verify_product).and_raise(Google::Apis::Error.new('invalid'))
    end

    it 'returns forbidden when Google Play rejects the issue receipt' do
      post :show, params: { id: issue.id, format: :json }
      expect(response).to have_http_status(:forbidden)
    end
  end
end

RSpec.describe ArticlesController, type: :controller do
  before do
    allow_any_instance_of(Issue).to receive(:index_document)
    allow_any_instance_of(Article).to receive(:index_document)
    allow_any_instance_of(Article).to receive(:update_document)
    allow_any_instance_of(Article).to receive(:delete_document)
  end

  describe 'POST body_android' do
    let(:article) { FactoryBot.create(:article) }
    let(:purchase) { instance_double(Services::GooglePlayVerification) }
    let(:receipt_json) do
      [{ productId: "#{article.issue.number}single", purchaseToken: 'bad-token' }].to_json
    end

    before do
      allow(controller.request).to receive(:raw_post).and_return(receipt_json)
      allow(Services::GooglePlayVerification).to receive(:new).and_return(purchase)
      allow(purchase).to receive(:verify_product).and_raise(Google::Apis::Error.new('invalid'))
    end

    it 'returns forbidden when Google Play rejects the article receipt' do
      post :body_android, params: { article_id: article.id, issue_id: article.issue.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
