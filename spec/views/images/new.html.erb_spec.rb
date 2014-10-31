require 'rails_helper'

describe "images/new", :type => :view do
  before(:each) do
    @showimage = FactoryGirl.create(:image)
    @article = @showimage.article
    @issue = @article.issue
  end

  it "renders new image form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => issue_article_images_path(@issue,@article,@showimage), :method => "post" do
    end
  end
end
