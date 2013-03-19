require 'spec_helper'

describe "institution/users/show" do
  before(:each) do
    @institution_user = assign(:institution_user, stub_model(Institution::User))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
