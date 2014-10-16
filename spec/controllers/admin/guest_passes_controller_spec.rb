require 'spec_helper'

describe Admin::GuestPassesController, :type => :controller do

  describe "GET 'index'" do
    context "as a unauthorized user" do
      it "redirects" do
        get 'index'
        expect(response).to redirect_to(issues_url)
      end
    end

    context "as an authorized user" do
      it "returns http success" do
        sign_in FactoryGirl.create(:admin_user)
        get 'index'
        expect(response).to be_success
      end
    end
  end

end
