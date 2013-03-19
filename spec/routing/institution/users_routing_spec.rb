require "spec_helper"

describe Institution::UsersController do
  describe "routing" do

    it "routes to #index" do
      get("/institution/users").should route_to("institution/users#index")
    end

    it "routes to #new" do
      get("/institution/users/new").should route_to("institution/users#new")
    end

    it "routes to #show" do
      get("/institution/users/1").should route_to("institution/users#show", :id => "1")
    end

    it "routes to #edit" do
      get("/institution/users/1/edit").should route_to("institution/users#edit", :id => "1")
    end

    it "routes to #create" do
      post("/institution/users").should route_to("institution/users#create")
    end

    it "routes to #update" do
      put("/institution/users/1").should route_to("institution/users#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/institution/users/1").should route_to("institution/users#destroy", :id => "1")
    end

  end
end
