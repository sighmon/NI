require "spec_helper"

describe UserMailer do
  describe "subscription_confirmation" do
    user = FactoryGirl.create(:user)
    let(:mail) { UserMailer.subscription_confirmation(user) }

    it "renders the headers" do
      mail.subject.should eq("New Internationalist Digital Subscription")
      mail.to.should eq([user.email])
      mail.from.should eq(["subscribe@newint.com.au"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
