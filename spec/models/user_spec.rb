require 'spec_helper'

describe User do
  describe "subscriber" do
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }

    it "has a valid subscription" do
      user.subscriber?.should be_true
    end

    it "receives a partial refund" do
      #set a predicatable duration
      subscription.duration = 3
      #price is 1 cent per week
      subscription.price_paid = 3*4
      Timecop.travel(DateTime.now+3.weeks) do
        subscription.expire_subscription
        subscription.refund.should == 2*4+1
      end
    end
  end

end

