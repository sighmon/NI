require 'rails_helper'

describe "images/show", type: :view do
  before(:each) do
    @showimage = FactoryBot.create(:image)
    @article = @showimage.article
    @issue = @article.issue
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
