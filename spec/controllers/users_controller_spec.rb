require 'rails_helper'

describe UsersController, type: :controller do

  context "as a user with a subscription" do

    let(:subscription) { FactoryBot.create(:subscription) }
    let(:user) { subscription.user }

    before(:each) do
      sign_in user
    end

    describe "JSON user information" do

      it "should have an expiry date, id and username" do
        get :show, params: {id: user.id, format: :json}
        # byebug
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["expiry"]).not_to eq("")
        expect(JSON.parse(response.body)["expiry"].to_date).to eq(user.expiry_date.to_date)
        # TODO: Write expiry test for paper & paper_only
        expect(JSON.parse(response.body)["id"]).to eq(user.id)
        expect(JSON.parse(response.body)["username"]).to eq(user.username)
      end

    end

    describe "the user with a paper only subscription" do

      it "should have an expiry_date +3m and expiry_date_paper_only" do
        # user.expiry_date should have 3 months added to it as a free trial
        # user.expiry_date_paper_only should be subscription.valid_from + duration
        subscription.paper_only = true
        subscription.save
        expect(user.expiry_date.to_date).to eq(subscription.valid_from.to_date + 3.months)
        expect(user.expiry_date_paper_only.to_date).to eq(subscription.valid_from.to_date + subscription.duration.months)
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
        get :show, params: {id: user.id, format: :json}
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
        get :show, params: {id: user.id, format: :json}
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
        get :show, params: {id: user.id, format: :json}
        # byebug
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["guest_passes"].count).to eq(1)
        expect(JSON.parse(response.body)["expiry"]).to eq(nil)
      end

    end

  end

  describe "newsletter widget visibility" do
    render_views

    let(:user) { FactoryBot.create(:user) }

    before(:each) do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("WHATCOUNTS_BASE_URL").and_return("https://mail.example.com")
      sign_in user
    end

    it "shows the widget for a standard user" do
      get :show, params: { id: user.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Email newsletter:")
    end

    it "does not show the widget for child users" do
      child_user = FactoryBot.create(:child_user)

      sign_in child_user

      get :show, params: { id: child_user.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Email newsletter:")
    end

    it "does not show the widget for users with a uk_id" do
      uk_user = FactoryBot.create(:uk_user)

      sign_in uk_user

      get :show, params: { id: uk_user.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Email newsletter:")
    end
  end

end
