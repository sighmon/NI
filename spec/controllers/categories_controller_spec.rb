require 'spec_helper'

describe CategoriesController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  context "With a category" do

    let (:category){FactoryGirl.create(:category)}

    describe "GET 'show'" do
      it "returns http success" do
        get 'show', :id => category.id
        response.should be_success
      end
    end

  end

end
