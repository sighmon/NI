require "spec_helper"

describe UserMailer do
  describe "subscription_confirmation" do
    let(:mail) { UserMailer.subscription_confirmation }

    it "renders the headers" do
      mail.subject.should eq("Subscription confirmation")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
