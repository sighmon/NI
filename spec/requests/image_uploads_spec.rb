require 'spec_helper'

# gives us login_as which devise uses internally
include Warden::Test::Helpers

describe "ImageUploads" do
  context "as an admin" do
    let(:admin) { FactoryGirl.create(:admin_user) }

    before(:each) do
      # poke the warden helper to login
      login_as admin, scope: :user
    end

    context "given an article" do
      let(:article) { FactoryGirl.create(:article) }
      describe "GET /issue/:id/article/:id/images/new" do
        it "works! (now write some real specs)" do
          # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
          get new_issue_article_image_path(article.issue.id,article.id)
          response.status.should be(200)
        end
      end
    end
  end
end
