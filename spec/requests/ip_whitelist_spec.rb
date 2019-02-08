require 'rails_helper'

describe "IP Whitelist", :type => :request do

  let(:parent) { FactoryBot.create(:subscription).user }
  let(:child) { FactoryBot.create(:user, ip_whitelist: "1.2.3.4", parent: parent) }
  let(:article) { FactoryBot.create(:article) }

  describe "GET /issue/:id/article/:id" do
    it "should be able to read the body" do
      #request.env["REMOTE_ADDR"] = user.ip_whitelist
      get issue_article_path(article.issue,article), params: {}, headers: {"REMOTE_ADDR" => child.ip_whitelist}
      expect(response.status).to eq(200)
    end
  end

end

describe "Not in IP Whitelist", :type => :request do

  let(:parent) { FactoryBot.create(:subscription).user }
  let(:child) { FactoryBot.create(:user, ip_whitelist: "1.2.3.4", parent: parent) }
  let(:article) { FactoryBot.create(:article) }

  describe "GET /issue/:id/article/:id" do
    it "should not be able to read the body" do
      #request.env["REMOTE_ADDR"] = user.ip_whitelist
      # get issue_article_path(article.issue,article), nil, "REMOTE_ADDR" => "4.3.2.1"
      # TOFIX: Even setting this to "1.2.3.4" still gives a 302
      get issue_article_path(article.issue,article), params: {}, headers: {"REMOTE_ADDR" => "4.3.2.1"}
      expect(response.status).to eq(302)
    end
  end

end

describe "No IP Whitelist entry", :type => :request do

  let(:parent) { FactoryBot.create(:subscription).user }
  let(:child) { FactoryBot.create(:user, ip_whitelist: "", parent: parent) }
  let(:article) { FactoryBot.create(:article) }

  describe "GET /issue/:id/article/:id" do
    it "should not be able to read the body" do
      #request.env["REMOTE_ADDR"] = user.ip_whitelist
      get issue_article_path(article.issue,article), params: {}, headers: {"REMOTE_ADDR" => "4.3.2.1"}
      expect(response.status).to eq(302)
    end
  end

end
