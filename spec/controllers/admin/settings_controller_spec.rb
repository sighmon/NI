require 'rails_helper'

describe Admin::SettingsController, type: :controller do

  context "as an admin user" do
    describe "GET 'index'" do
      it "returns http success" do
        user = FactoryBot.create(:admin_user)
        sign_in user
        get 'index'
        expect(response).to be_successful
      end
    end
  end

  context "as a manager user" do
    describe "GET 'index'" do
      it "returns http success" do
        user = FactoryBot.create(:manager_user)
        sign_in user
        get 'index'
        expect(response).to be_successful
      end
    end
  end

  context "as a guest user" do
    describe "GET 'index'" do
      it "returns http success" do
        user = FactoryBot.create(:user)
        sign_in user
        get 'index'
        expect(response).not_to be_successful
      end
    end
  end

end
