require 'rails_helper'

include Warden::Test::Helpers

describe "Institution::Users", :type => :request do
  context "as an institution"
  let(:child) { FactoryGirl.create(:child_user) }
  before(:each) do
    login_as child.parent, scope: :user
  end
  describe "GET /institution/users" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get institution_users_path
      expect(response.status).to be(200)
    end
  end
end
