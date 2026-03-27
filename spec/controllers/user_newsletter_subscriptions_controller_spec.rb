require "rails_helper"

describe UserNewsletterSubscriptionsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  describe "GET show" do
    it "returns the current newsletter status for the signed in user" do
      result = instance_double(
        WhatCounts::NewsletterSubscription::Result,
        success?: true,
        subscribed: true,
        message: "Subscribed to the email newsletter."
      )

      sign_in user
      expect(WhatCounts::NewsletterSubscription).to receive(:new)
        .with(email: user.email)
        .and_return(instance_double(WhatCounts::NewsletterSubscription, status: result))

      get :show, params: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "subscribed" => true,
        "message" => "Subscribed to the email newsletter."
      )
    end
  end

  describe "POST create" do
    it "subscribes the signed in user" do
      result = instance_double(
        WhatCounts::NewsletterSubscription::Result,
        success?: true,
        subscribed: true,
        message: "Thanks for signing up to the newsletter."
      )

      sign_in user
      expect(WhatCounts::NewsletterSubscription).to receive(:new)
        .with(email: user.email)
        .and_return(instance_double(WhatCounts::NewsletterSubscription, subscribe: result))

      post :create, params: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "subscribed" => true,
        "message" => "Thanks for signing up to the newsletter."
      )
    end
  end

  describe "DELETE destroy" do
    it "unsubscribes the signed in user" do
      result = instance_double(
        WhatCounts::NewsletterSubscription::Result,
        success?: true,
        subscribed: false,
        message: "You have been unsubscribed from the newsletter."
      )

      sign_in user
      expect(WhatCounts::NewsletterSubscription).to receive(:new)
        .with(email: user.email)
        .and_return(instance_double(WhatCounts::NewsletterSubscription, unsubscribe: result))

      delete :destroy, params: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "subscribed" => false,
        "message" => "You have been unsubscribed from the newsletter."
      )
    end
  end

  describe "authorization" do
    it "rejects requests for another user" do
      sign_in user

      get :show, params: { user_id: FactoryBot.create(:user).id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
