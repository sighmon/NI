require 'rails_helper'

RSpec.describe Admin::PushNotificationsController, type: :controller do

  describe "GET #index" do
    it "returns http redirect" do
      get :index
      expect(response).to have_http_status(:redirect)
    end

    it "admin returns http success" do
      user = FactoryBot.create(:admin_user)
      sign_in user
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #send_notifications" do
    let(:user) { FactoryBot.create(:admin_user) }

    before do
      sign_in user
      allow(ApplicationHelper).to receive(:rpush_send_notifications)
        .and_return(attempted: 1, delivered: 1, failed: 0, pending: 0)
    end

    it "reports confirmed deliveries" do
      post :send_notifications

      expect(ApplicationHelper).to have_received(:rpush_send_notifications)
      expect(response).to redirect_to(admin_push_notifications_path)
      expect(flash[:notice]).to eq("1 push notifications delivered.")
    end

    it "reports notifications that remain pending" do
      allow(ApplicationHelper).to receive(:rpush_send_notifications)
        .and_return(attempted: 1, delivered: 0, failed: 0, pending: 1)

      post :send_notifications

      expect(response).to redirect_to(admin_push_notifications_path)
      expect(flash[:error]).to include("1 pending")
    end

    it "reports configuration errors without raising a 500" do
      allow(ApplicationHelper).to receive(:rpush_send_notifications).and_raise(KeyError, "missing Firebase credentials")

      post :send_notifications

      expect(response).to redirect_to(admin_push_notifications_path)
      expect(flash[:error]).to include("missing Firebase credentials")
    end
  end

end
