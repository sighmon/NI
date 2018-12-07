require 'rails_helper'

describe UserMailer, :type => :mailer do

  describe "user_signup_confirmation" do
    let(:user) { FactoryBot.create(:user) }
    let(:issue) { FactoryBot.create(:published_issue) }
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
      expect(mail.body.encoded).to match(user.username)
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
      expect(mail.body.encoded).to match("<body")
    end

    context "is a UK user" do
      let(:user) { FactoryBot.create(:uk_user) }
      let(:mail) {
        @issue = issue
        UserMailer.user_signup_confirmation_uk(user)
      }

      it "renders the headers" do
        expect(mail.subject).to eq("New Internationalist - Welcome!")
        expect(mail.to).to eq([user.email])
        expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("Thank you for registering an account with your UK")
        expect(mail.body.encoded).to match(user.username)
        # Check that the MJML > HTML renderer has worked
        expect(mail.body.encoded).not_to match("mj-body")
      end
    end

    context "is an institutional user" do
      let(:user) { FactoryBot.create(:institution_user) }
      let(:mail) {
        @issue = issue
        UserMailer.make_institutional_confirmation(user)
      }

      it "renders the headers" do
        expect(mail.subject).to eq("New Internationalist Digital Subscription - Institution confirmation")
        expect(mail.to).to eq([user.email])
        expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("You've now been made an Institutional user")
        expect(mail.body.encoded).to match(user.username)
        # Check that the MJML > HTML renderer has worked
        expect(mail.body.encoded).not_to match("mj-body")
      end
    end
  end

  describe "subscription_confirmation" do
    let(:subscription) { FactoryBot.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryBot.create(:published_issue) }
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
      expect(mail.body.encoded).to match(user.username)
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end

    context "for a 10 year media subscription" do
      let(:subscription) { FactoryBot.create(:media_subscription) }
      let(:user) { subscription.user }
      let(:mail) {
        @issue = issue
        UserMailer.media_subscription_confirmation(user)
      }

      it "renders the headers" do
        expect(mail.subject).to eq("Complimentary New Internationalist Digital Subscription - Media")
        expect(mail.to).to eq([user.email])
        expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("Lucky you! You've been given a complimentary 10 year media")
        expect(mail.body.encoded).to match(user.username)
        # Check that the MJML > HTML renderer has worked
        expect(mail.body.encoded).not_to match("mj-body")
      end
    end

    context "with a paper only subscription" do
      let(:subscription) { FactoryBot.create(:paper_only_subscription) }
      let(:user) { subscription.user }
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
        expect(mail.body.encoded).to match(user.username)
        # Check that the MJML > HTML renderer has worked
        expect(mail.body.encoded).not_to match("mj-body")
        # Check that the body includes Your subscription is due for renewal:
        expect(mail.body.encoded).to match("Your subscription is due for renewal:")
        # And the date is correct
        expect(mail.body.encoded).to match(subscription.expiry_date_paper_only.try(:strftime, "%e %B, %Y"))
        # Check that the body includes the free 3 month trial.
        expect(mail.body.encoded).to match("3-month trial")
        # And the date is correct
        expect(mail.body.encoded).to match(subscription.expiry_date.try(:strftime, "%e %B, %Y"))
      end
    end

    context "for a free subscription" do
      let(:subscription) { FactoryBot.create(:subscription) }
      let(:user) { subscription.user }
      let(:mail) {
        @issue = issue
        UserMailer.free_subscription_confirmation(user,12)
      }

      it "renders the headers" do
        expect(mail.subject).to eq("Complimentary New Internationalist Digital Subscription")
        expect(mail.to).to eq([user.email])
        expect(mail.from).to eq([ENV["DEVISE_EMAIL_ADDRESS"]])
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("Lucky you! You've been given a complimentary 12 month")
        expect(mail.body.encoded).to match(user.username)
        # Check that the MJML > HTML renderer has worked
        expect(mail.body.encoded).not_to match("mj-body")
      end
    end
  end

  describe "subscription_cancellation" do
    let(:subscription) { FactoryBot.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryBot.create(:published_issue) }
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
      expect(mail.body.encoded).to match(user.username)
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

  describe "subscription_cancelled_via_paypal" do
    let(:subscription) { FactoryBot.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryBot.create(:published_issue) }
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
      expect(mail.body.encoded).to match(user.username)
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

  describe "issue_purchase" do
    let(:purchase) { FactoryBot.create(:purchase) }
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
      expect(mail.body.encoded).to match(purchase.user.username)
      # Check that the MJML > HTML renderer has worked
      expect(mail.body.encoded).not_to match("mj-body")
    end
  end

end
