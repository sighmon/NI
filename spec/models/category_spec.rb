require 'rails_helper'

describe Category, :type => :model do

   it "can be added to an article" do
     category = FactoryBot.create(:category)
     article = FactoryBot.create(:article)
     article.categories << category
     expect(category.articles).to eq([article])
   end

end
