require 'rails_helper'

describe "pages/show", :type => :view do
  before(:each) do
    @page = assign(:page, stub_model(Page,
      :title => "Title",
      :permalink => "Permalink",
      :body => "MyText",
      :created_at => DateTime.now
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    expect(rendered).to match(/Title/)
    #rendered.should match(/Permalink/)
    expect(rendered).to match(/MyText/)
  end
end
