require 'spec_helper'

describe "institution/users/show" do
  before(:each) do
    @user = assign(:user, FactoryGirl.create(:child_user))
    view.stub(:current_user).and_return(@user.parent)
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
