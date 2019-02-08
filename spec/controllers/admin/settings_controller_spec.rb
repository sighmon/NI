require 'rails_helper'

describe Admin::SettingsController, :type => :controller do

  describe "GET 'index'" do
    it "returns http success" do
      user = FactoryBot.create(:admin_user)
      sign_in user
      get 'index'
      expect(response).to be_successful
    end
  end
 
end
