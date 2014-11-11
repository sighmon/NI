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
          post :send_push_notification, :issue_id => issue.id, :alert_text => "Test."
          expect(response.status).to eq(302)
        end

      end
    end
  end
end

