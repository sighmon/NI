require 'spec_helper'

describe "institution/users/edit" do
  before(:each) do
    @user = assign(:user, stub_model(User))
  end

  it "renders the edit user form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => institution_users_path(@user), :method => "post" do
    end
  end
end
