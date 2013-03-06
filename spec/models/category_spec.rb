require 'spec_helper'

describe Category do

   it "can be added to an article" do
     category = FactoryGirl.create(:category)
     article = FactoryGirl.create(:article)
     article.categories << category
     category.articles.should eq([article])
   end

end
