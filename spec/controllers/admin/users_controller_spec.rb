require 'rails_helper'

describe Admin::UsersController, :type => :controller do
  before :each do
    user = FactoryGirl.create(:admin_user)
    sign_in user
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end
  end

end
