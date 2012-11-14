require 'spec_helper'

describe User do

  context "user" do
    let(:user) do
      FactoryGirl.create(:user)
    end
  
    it "should have a username" do
      user.username.should_not == ""
    end

    it "should not be a subscriber" do
      user.subscriber?.should be_false
    end

  end

  context "subscriber" do


    before(:all) do
      Timecop.freeze(2012,1,1,0,0,0)
      @subscription = FactoryGirl.create(:subscription)
      @user = @subscription.user
    end

    #let(:user) { subscription.user }

    it "has a valid subscription" do
      @user.subscriber?.should be_true
    end

    it "receives a partial refund" do
      @subscription.valid_from = DateTime.parse("2012/1/1")
      #set a predicatable duration
      @subscription.duration = 3
      #price is 1 cent per day 
      @subscription.price_paid = 91 
      Timecop.freeze(2012,1,22,0,0,0) do
        @subscription.expire_subscription
        @subscription.refund.should == 91-21
      end
    end
  end

end

