require 'rails_helper'

describe Admin::UsersController, :type => :controller do

  context "as an admin user" do
    before :each do
      user = FactoryBot.create(:admin_user)
      sign_in user
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).to be_successful
      end
    end
  end

  context "as a manager user" do
    before :each do
      user = FactoryBot.create(:manager_user)
      sign_in user
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).to be_successful
      end
    end
  end

  context "as a guest user" do
    before :each do
      user = FactoryBot.create(:user)
      sign_in user
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).not_to be_successful
      end
    end
  end

  context "as an institution user" do
    before :each do
      user = FactoryBot.create(:institution_user)
      sign_in user
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).not_to be_successful
      end
    end
  end

  context "as a child user" do
    before :each do
      user = FactoryBot.create(:child_user)
      sign_in user
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).not_to be_successful
      end
    end
  end

end
