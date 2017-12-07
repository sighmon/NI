require 'rails_helper'

describe UsersController, :type => :controller do

  context "as a user with a subscription" do

    let(:subscription) { FactoryBot.create(:subscription) }
    let(:user) { subscription.user }

    before(:each) do
      sign_in user
    end

    describe "JSON user information" do

      it "should have an expiry date, id and username" do
        get :show, params: {:id => user.id, :format => :json}
        # byebug
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["expiry"]).not_to eq("")
        expect(JSON.parse(response.body)["expiry"].to_date).to eq(user.expiry_date.to_date)
        expect(JSON.parse(response.body)["id"]).to eq(user.id)
        expect(JSON.parse(response.body)["username"]).to eq(user.username)
      end

    end

  end

  context "as a user with a purchase" do

    let(:purchase) { FactoryBot.create(:purchase) }
    let(:user) { purchase.user }
    let(:issue) { purchase.issue }

    before(:each) do
      sign_in user
    end

    describe "JSON user information" do

      it "should have a purchase" do
        get :show, params: {:id => user.id, :format => :json}
        # byebug
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["purchases"].count).to eq(1)
        expect(JSON.parse(response.body)["purchases"].first).to eq(purchase.issue.number)
        expect(JSON.parse(response.body)["expiry"]).to eq(nil)
      end

    end

  end

  context "as a user with a favourite" do

    let(:favourite) { FactoryBot.create(:favourite) }
    let(:user) { favourite.user }
    let(:article) { favourite.article }

    before(:each) do
      sign_in user
    end

    describe "JSON user information" do

      it "should have a favourite" do
        get :show, params: {:id => user.id, :format => :json}
        # byebug
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["favourites"].count).to eq(1)
        expect(JSON.parse(response.body)["expiry"]).to eq(nil)
      end

    end

  end

  context "as a user with a guest pass" do

    let(:guest_pass) { FactoryBot.create(:guest_pass) }
    let(:user) { guest_pass.user }
    let(:article) { guest_pass.article }

    before(:each) do
      sign_in user
    end

    describe "JSON user information" do

      it "should have a guest pass" do
        get :show, params: {:id => user.id, :format => :json}
        # byebug
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["guest_passes"].count).to eq(1)
        expect(JSON.parse(response.body)["expiry"]).to eq(nil)
      end

    end

  end

end
