require 'rails_helper'

describe GuestPass, type: :model do

  it "has an article" do
    gp = FactoryBot.create(:guest_pass)
    expect(gp.article_id).not_to be_nil
  end

  it "has a key" do
    gp = FactoryBot.create(:guest_pass)
    expect(gp.key).not_to be_nil
  end

end
