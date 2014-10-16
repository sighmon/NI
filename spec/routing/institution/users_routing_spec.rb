require "spec_helper"

describe Institution::UsersController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get("/institution/users")).to route_to("institution/users#index")
    end

    it "routes to #new" do
      expect(get("/institution/users/new")).to route_to("institution/users#new")
    end

    it "routes to #show" do
      expect(get("/institution/users/1")).to route_to("institution/users#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/institution/users/1/edit")).to route_to("institution/users#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/institution/users")).to route_to("institution/users#create")
    end

    it "routes to #update" do
      expect(put("/institution/users/1")).to route_to("institution/users#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/institution/users/1")).to route_to("institution/users#destroy", :id => "1")
    end

  end
end
