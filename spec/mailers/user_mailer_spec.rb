require 'rails_helper'

describe UserMailer, :type => :mailer do
  describe "subscription_confirmation" do
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }
    let(:mail) { UserMailer.subscription_confirmation(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("New Internationalist Digital Subscription")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["subscribe@newint.com.au"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
