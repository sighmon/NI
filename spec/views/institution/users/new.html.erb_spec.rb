require 'rails_helper'

describe "institution/users/new", type: :view do
  before(:each) do
    assign(:user, stub_model(User).as_new_record)
  end

  it "renders new user form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: institution_users_path, method: "post" do
    end
  end
end
