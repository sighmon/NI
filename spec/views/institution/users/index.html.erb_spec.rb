require 'rails_helper'

describe "institution/users/index", :type => :view do
  before(:each) do
    assign(:users, [
      @child = FactoryBot.create(:child_user),
    ])
    assign(:user, @child.parent)
  end

  it "renders a list of institution/users" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
