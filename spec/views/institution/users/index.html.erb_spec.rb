require 'spec_helper'

describe "institution/users/index" do
  before(:each) do
    assign(:institution_users, [
      stub_model(Institution::User),
      stub_model(Institution::User)
    ])
  end

  it "renders a list of institution/users" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
