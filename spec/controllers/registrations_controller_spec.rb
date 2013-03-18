require 'spec_helper'

describe RegistrationsController do

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  context "as a guest" do
    describe "POST create" do
      context "with valid params" do
        it "creates a new user" do
          user = FactoryGirl.build(:user)
          attributes = { username: user.username, email: user.email, password: "password", password_confirmation: "password" }
          expect {
            post :create, {:user => attributes}
          }.to change(User, :count).by(1)
        end
      end
    end
  end

end

