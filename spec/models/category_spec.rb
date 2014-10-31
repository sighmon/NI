require 'rails_helper'

describe Category, :type => :model do

   it "can be added to an article" do
     category = FactoryGirl.create(:category)
     article = FactoryGirl.create(:article)
     article.categories << category
     expect(category.articles).to eq([article])
   end

end
