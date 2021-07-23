require 'rails_helper'

describe RegistrationsController do

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  context "as a guest" do
    describe "POST create" do
      context "with valid params" do
        it "creates a new user" do
          user = FactoryBot.build(:user)
          attributes = { username: user.username, email: user.email, password: "password", password_confirmation: "password" }
          expect {
            post :create, params: {:user => attributes}
          }.to change(User, :count).by(1)
        end
      end

      context "with a blank username" do
        it "doesn't create a new user" do
          user = FactoryBot.build(:user)
          attributes = { username: "", email: user.email, password: "password", password_confirmation: "password" }
          expect {
            post :create, params: {:user => attributes}
          }.to change(User, :count).by(0)
        end
      end

      context "with a blank email" do
        it "doesn't create a new user" do
          user = FactoryBot.build(:user)
          attributes = { username: user.username, email: "", password: "password", password_confirmation: "password" }
          expect {
            post :create, params: {:user => attributes}
          }.to change(User, :count).by(0)
        end
      end
    end
  end
 
  context "as a user" do
    let(:user) { FactoryBot.create(:user) }
    before (:each) do
      sign_in user
    end
    describe "POST create" do
      context "with valid params" do
        it "doesn't create a new user" do
          new_user = FactoryBot.build(:user)
          attributes = { username: new_user.username, email: new_user.email, password: "password", password_confirmation: "password" }
          expect {
            post :create, params: {:user => attributes}
          }.to change(User, :count).by(0)
        end
      end
    end
    describe "PUT update" do
      context "with valid email" do
        it "updates the email" do
          newemail = "newemail@example.com"
          attributes = { username: user.username, email: newemail, current_password: user.password }
          expect {
            put :update, params: { user: attributes }
            user.reload
          }.to change(user, :email).to(newemail)
        end
      end
    end
  end

  # this is really testing cancan more than Devise....
  context "as a child" do
    let(:user) do
      parent = FactoryBot.create(:user)
      user = FactoryBot.create(:user)
      parent.children << user
      user
    end
    describe "PUT update" do
      context "with valid email" do
        it "does not update the email" do
          newemail = "newemail@example.com"
          attributes = { username: user.username, email: newemail, current_password: user.password }
          expect_any_instance_of(User).not_to receive(:update)
          put :update, params: { user: attributes }
        end
      end
    end
  end
end

