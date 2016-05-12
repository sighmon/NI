require 'rails_helper'

describe UserMailer, :type => :mailer do

  describe "user_signup_confirmation" do
    let(:user) { FactoryGirl.create(:user) }
    let(:issue) { FactoryGirl.create(:published_issue) }
    let(:mail) {
      @issue = issue
      UserMailer.user_signup_confirmation(user)
    }

    it "renders the headers" do
      expect(mail.subject).to eq("New Internationalist - Welcome!")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Thank you for registering an account")
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

  describe "subscription_confirmation" do
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryGirl.create(:published_issue) }
    let(:mail) {
      @issue = issue
      UserMailer.subscription_confirmation(subscription)
    }

    it "renders the headers" do
      expect(mail.subject).to eq("New Internationalist Digital Subscription")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

  describe "subscription_cancellation" do
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryGirl.create(:published_issue) }
    let(:mail) {
      @issue = issue
      UserMailer.subscription_cancellation(subscription)
    }

    it "renders the headers" do
      expect(mail.subject).to eq("Cancelled New Internationalist Digital Subscription")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Your subscription is now cancelled")
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

  describe "subscription_cancelled_via_paypal" do
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryGirl.create(:published_issue) }
    let(:mail) {
      @issue = issue
      UserMailer.subscription_cancelled_via_paypal(subscription)
    }

    it "renders the headers" do
      expect(mail.subject).to eq("Cancelled New Internationalist Digital Subscription")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Your automatic-renewal has now been cancelled via PayPal")
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

  describe "issue_purchase" do
    let(:purchase) { FactoryGirl.create(:purchase) }
    let(:mail) {
      UserMailer.issue_purchase(purchase)
    }

    it "renders the headers" do
      expect(mail.subject).to eq("New Internationalist Purchase - #{purchase.issue.number} - #{purchase.issue.title}")
      expect(mail.to).to eq([purchase.user.email])
      expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Thank you for purchasing a digital issue")
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

end
