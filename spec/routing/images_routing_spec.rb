require 'rails_helper'

describe ImagesController, type: :routing do
  describe "routing" do

    before (:each) do
      image = FactoryBot.create(:image)
    end

    it "routes to #index" do
      expect(get("/issues/1/articles/1/images")).to route_to("images#index", article_id: "1", issue_id: "1")
    end

    it "routes to #new" do
      expect(get("/issues/1/articles/1/images/new")).to route_to("images#new", article_id: "1", issue_id: "1")
    end

    it "routes to #show" do
      expect(get("/issues/1/articles/1/images/1")).to route_to("images#show", id: "1", article_id: "1", issue_id: "1")
    end

    it "routes to #edit" do
      expect(get("/issues/1/articles/1/images/1/edit")).to route_to("images#edit", id: "1", article_id: "1", issue_id: "1")
    end

    it "routes to #create" do
      expect(post("/issues/1/articles/1/images")).to route_to("images#create", article_id: "1", issue_id: "1")
    end

    it "routes to #update" do
      expect(put("/issues/1/articles/1/images/1")).to route_to("images#update", id: "1", article_id: "1", issue_id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/issues/1/articles/1/images/1")).to route_to("images#destroy", id: "1", article_id: "1", issue_id: "1")
    end

  end
end
