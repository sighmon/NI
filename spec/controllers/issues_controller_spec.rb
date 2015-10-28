require 'rails_helper'


describe IssuesController, :type => :controller do

  context "as a guest" do
   
    context "with an issue" do
      let(:issue) { FactoryGirl.create(:issue) }

      describe "GET email" do

        it "works" do
          get :email, :issue_id => issue.id
          expect(response.status).to eq(200)
        end

      end

      describe "POST push notification" do

        it "should not be able to send a push notification" do
          post :send_push_notification, :issue_id => issue.id
          expect(response).to redirect_to issues_url
        end

      end
    end
  end

  context "as a user with an issue" do

    let(:user) { FactoryGirl.create(:user) }
    let(:issue) { FactoryGirl.create(:issue) }

    before(:each) do
      sign_in user
    end

    describe "POST push notification" do

      it "should not be able to send a push notification" do
        post :send_push_notification, :issue_id => issue.id
        expect(response).to redirect_to issues_url
      end

    end

  end

  context "as a user with a purchase" do

    let(:purchase) { FactoryGirl.create(:purchase) }
    let(:user) { purchase.user }
    let(:issue) { purchase.issue }

    before(:each) do
      sign_in user
    end

    describe "POST iOS download issue for offline reading" do

      it "should be able to download issue" do
        post :show, :id => issue.id, :format => 'json'
        # TODO: FIX sort out why it's returning 302 redirected.
        expect(response.status).to eq(200)
      end

    end

  end

  context "as a subscriber with an issue" do

    before(:all) do
      Timecop.freeze(2012,1,1,0,0,0)
    end

    after(:all) do
      Timecop.return() 
    end
    
    let(:user) { FactoryGirl.create(:user) }
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryGirl.create(:issue) }

    it "has a valid subscription" do
      expect(user.subscriber?).to be_truthy
    end

    describe "POST push notification" do

      it "should not be able to send a push notification" do
        post :send_push_notification, :issue_id => issue.id
        expect(response).to redirect_to issues_url
      end

    end
    
  end

end

