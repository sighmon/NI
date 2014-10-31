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
    end
  end
end

