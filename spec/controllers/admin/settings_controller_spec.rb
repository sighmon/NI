require 'spec_helper'

describe Admin::SettingsController do

  describe "GET 'index'" do
    it "returns http success" do
      user = FactoryGirl.create(:admin_user)
      sign_in user
      get 'index'
      response.should be_success
    end
  end
 
end
