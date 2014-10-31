require 'rails_helper'

describe "images/index", :type => :view do
  before(:each) do
    image = FactoryGirl.create(:image)
    FactoryGirl.create(:image,article: image.article)
    @article = image.article
    @issue = @article.issue
    @images = @article.images
  end

  it "renders a list of images" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
