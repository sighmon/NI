require 'spec_helper'
require 'cancan/matchers'

describe User, :type => :model do

  context "institution" do
    let(:user) do
      FactoryGirl.create(:user, :institution => true)
    end

    let(:ability) { Ability.new(user) }

    context "with a child" do
      before(:each) do
        child = FactoryGirl.create(:user)
        user.children << child
      end
      it "can manage child" do
        expect(ability).to be_able_to(:manage, user.children.first)
      end
      it "destroys child when destroyed" do
        child_id = user.children.first.id
        user.destroy
        expect { User.find(child_id) }.to raise_exception
      end
    end

    it "can create a child without an email" do
      newuser = FactoryGirl.build(:user)
      child = user.children.create(username: newuser.username, password: newuser.password)
      expect(child.email).to be_blank
    end

  end

  context "normal user" do
    let(:user) do
      FactoryGirl.create(:user)
    end
  
    let(:ability) { Ability.new(user) }

    it "should have a username" do
      expect(user.username).not_to eq("")
    end

    it "should not have a uk_id" do
      expect(user.uk_id).to be_nil
    end

    it "should not have a uk_expiry" do
      expect(user.uk_expiry).to be_nil
    end

    it "should not be a subscriber" do
      expect(user.subscriber?).to be_falsey
    end

    context "without a parent" do
      it "can update itself" do
        expect(ability).to be_able_to(:manage, user)
      end
    end

    context "with a subscriber parent" do
      before(:each) do
        sub = FactoryGirl.create(:subscription)
        sub.user.children << user
      end
      it "has a subscription" do
        expect(user.subscriber?).to be_truthy
      end
      it "can't update itself" do
        expect(ability).not_to be_able_to(:update, user)
      end
      it "doesn't destroy parent when destroyed" do
        parent_id = user.parent.id
        user.destroy
        expect(User.find(parent_id)).not_to be_nil
      end
    end

    context "with a child" do
      before(:each) do
        child = FactoryGirl.create(:user)
        user.children << child
      end
      it "can manage child" do
        expect(ability).to be_able_to(:manage, user.children.first)
      end
      it "cannot manage a non-child user" do
        sibling = FactoryGirl.create(:user)
        expect(ability).not_to be_able_to(:manage, sibling)
      end
    end

  end

  context "uk user" do
    let(:user) do
      FactoryGirl.create(:uk_user)
    end
  
    let(:ability) { Ability.new(user) }

    it "should have a username" do
      expect(user.username).not_to eq("")
    end

    it "should have a uk_id" do
      expect(user.uk_id).to be_truthy
    end

    it "should have a uk_expiry" do
      expect(user.uk_expiry).to be_truthy
    end

    it "should not be a subscriber" do
      expect(user.subscriber?).to be_falsey
    end
  end

  context "subscriber" do


    before(:all) do
      Timecop.freeze(2012,1,1,0,0,0)
    end

    after(:all) do
      Timecop.return() 
    end
  
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }

    it "has a valid subscription" do
      expect(user.subscriber?).to be_truthy
    end

    it "receives a partial refund" do
      #set a predicatable duration
      subscription.duration = 3
      #price is 1 cent per day 
      subscription.price_paid = 91 
      Timecop.freeze(2012,1,22,0,0,0) do
        subscription.expire_subscription
        expect(subscription.refund).to eq(91-21)
      end
    end

    it "receives a full refund if the subscription hasn't started yet" do
      subscription.price_paid = 91
      Timecop.freeze(2011,1,1,0,0,0) do
        subscription.expire_subscription
        expect(subscription.refund).to eq(91)
      end
    end
  end

end

