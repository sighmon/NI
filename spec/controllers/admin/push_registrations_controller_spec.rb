require 'rails_helper'

RSpec.describe Admin::PushRegistrationsController, type: :controller do

  describe "GET #index" do
    it "returns http redirect" do
      get :index
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET #index" do
    it "returns http success" do
      user = FactoryBot.create(:admin_user)
      sign_in user
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
