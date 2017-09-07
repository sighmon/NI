require 'rails_helper'

describe "GuestPasses", :type => :request do

  let(:guest_pass) { FactoryGirl.create(:guest_pass) }

  describe "GET /issue/:id/article/:id?utm_source=:key" do
    it "is possible to see an article with a valid guest pass" do
      
      get issue_article_path(guest_pass.article.issue,guest_pass.article), params: {:utm_source => guest_pass.key}
      expect(response.status).to be(200)
    end
  end
end
