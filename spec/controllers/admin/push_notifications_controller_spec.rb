require 'rails_helper'

RSpec.describe Admin::PushNotificationsController, type: :controller do

  describe "GET #index" do
    it "returns http redirect" do
      get :index
      expect(response).to have_http_status(:redirect)
    end

    it "admin returns http success" do
      user = FactoryGirl.create(:admin_user)
      sign_in user
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
