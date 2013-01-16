require 'spec_helper'

describe GuestPass do

  it "has an article" do
    gp = FactoryGirl.create(:guest_pass)
    gp.article_id.should_not be_nil
  end

  it "has a key" do
    gp = FactoryGirl.create(:guest_pass)
    gp.key.should_not be_nil
  end

end
