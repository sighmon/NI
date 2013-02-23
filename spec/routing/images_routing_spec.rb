require "spec_helper"

describe ImagesController do
  describe "routing" do

    before (:each) do
      image = FactoryGirl.create(:image)
    end

    it "routes to #index" do
      get("/issues/1/articles/1/images").should route_to("images#index", :article_id => "1", :issue_id => "1")
    end

    it "routes to #new" do
      get("/issues/1/articles/1/images/new").should route_to("images#new", :article_id => "1", :issue_id => "1")
    end

    it "routes to #show" do
      get("/issues/1/articles/1/images/1").should route_to("images#show", :id => "1", :article_id => "1", :issue_id => "1")
    end

    it "routes to #edit" do
      get("/issues/1/articles/1/images/1/edit").should route_to("images#edit", :id => "1", :article_id => "1", :issue_id => "1")
    end

    it "routes to #create" do
      post("/issues/1/articles/1/images").should route_to("images#create", :article_id => "1", :issue_id => "1")
    end

    it "routes to #update" do
      put("/issues/1/articles/1/images/1").should route_to("images#update", :id => "1", :article_id => "1", :issue_id => "1")
    end

    it "routes to #destroy" do
      delete("/issues/1/articles/1/images/1").should route_to("images#destroy", :id => "1", :article_id => "1", :issue_id => "1")
    end

  end
end
