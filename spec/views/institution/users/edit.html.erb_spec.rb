require 'spec_helper'

describe "institution/users/edit" do
  before(:each) do
    @institution_user = assign(:institution_user, stub_model(Institution::User))
  end

  it "renders the edit institution_user form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => institution_users_path(@institution_user), :method => "post" do
    end
  end
end
