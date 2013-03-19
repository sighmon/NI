require 'spec_helper'

describe "institution/users/new" do
  before(:each) do
    assign(:institution_user, stub_model(Institution::User).as_new_record)
  end

  it "renders new institution_user form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => institution_users_path, :method => "post" do
    end
  end
end
