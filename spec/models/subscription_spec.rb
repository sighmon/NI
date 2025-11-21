require 'rails_helper'

describe Subscription, type: :model do
  
  context "paper only" do

    before(:each) do
      Settings.subscription_price = 600
    end

    it "calculates the right subscription price" do
      options = {
        paper: true,
        paper_only: true
      }
      expect(Subscription.calculate_subscription_price(12, options)).to eq(8800)
    end

    context "institution" do

      it "calculates the right subscription price" do
        options = {
          paper: true,
          paper_only: true,
          institution: true
        }
        expect(Subscription.calculate_subscription_price(12, options)).to eq(10800)
      end

    end

  end
  
end
