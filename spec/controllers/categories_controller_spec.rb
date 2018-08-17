require 'rails_helper'

describe CategoriesController, :type => :controller do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_successful
    end
  end

  context "With a category" do

    let (:category){FactoryBot.create(:category)}

    describe "GET 'show'" do
      it "returns http success" do
        get 'show', params: {:id => category.id}
        expect(response).to be_successful
      end
    end

  end

end
