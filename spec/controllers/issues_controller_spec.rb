require 'spec_helper'


describe IssuesController do

  context "as a guest" do
   
    context "with an issue" do
      let(:issue) { FactoryGirl.create(:issue) }

      describe "GET email" do

        it "works" do
          get :email, :issue_id => issue.id
          response.status.should eq(200)
        end

      end
    end
  end
end

