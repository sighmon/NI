require 'rails_helper'
require 'cancan/matchers'

describe User, :type => :model do

  context "institution" do
    let(:user) do
      FactoryBot.create(:user, :institution => true)
    end

    let(:ability) { Ability.new(user) }

    context "with a child" do
      before(:each) do
        child = FactoryBot.create(:user)
        user.children << child
      end
      it "can manage child" do
        expect(ability).to be_able_to(:manage, user.children.first)
      end
      it "destroys child when destroyed" do
        child_id = user.children.first.id
        user.destroy
        expect { User.find(child_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "can create a child without an email" do
      newuser = FactoryBot.build(:user)
      child = user.children.create(username: newuser.username, password: newuser.password)
      expect(child.email).to be_blank
    end

  end

  context "normal user" do
    let(:user) do
      FactoryBot.create(:user)
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

    it "should not be able to manage an issue" do
      issue = FactoryBot.create(:issue)
      expect(ability).not_to be_able_to(:manage, issue)
    end

    it "should be able to read an issue" do
      issue = FactoryBot.create(:issue, :published => true)
      expect(ability).to be_able_to(:read, issue)
    end

    it "should not be able to read an article" do
      article = FactoryBot.create(:article)
      expect(ability).not_to be_able_to(:read, article)
    end

    it "should not be able to manage an article" do
      article = FactoryBot.create(:article)
      expect(ability).not_to be_able_to(:manage, article)
    end

    it "should not be able to read an unpublished article" do
      article = FactoryBot.create(:article, :unpublished => true)
      expect(ability).not_to be_able_to(:read, article)
    end

    it "should be able to read a trial article" do
      article = FactoryBot.create(:article, :trialarticle => true)
      expect(ability).to be_able_to(:read, article)
    end

    it "should be able to read a trial issue's article" do
      article = FactoryBot.create(:article)
      article.issue.trialissue = true
      expect(ability).to be_able_to(:read, article)
    end

    it "should not be able to manage a push registration" do
      push_registration = FactoryBot.create(:push_registration)
      expect(ability).not_to be_able_to(:manage, push_registration)
    end

    it "should not be able to manage a payment notifications" do
      payment_notification = FactoryBot.create(:payment_notification)
      expect(ability).not_to be_able_to(:manage, payment_notification)
    end

    context "without a parent" do
      it "can update itself" do
        expect(ability).to be_able_to(:manage, user)
      end
    end

    context "with a subscriber parent" do
      before(:each) do
        sub = FactoryBot.create(:subscription)
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
        child = FactoryBot.create(:user)
        user.children << child
      end
      it "can manage child" do
        expect(ability).to be_able_to(:manage, user.children.first)
      end
      it "cannot manage a non-child user" do
        sibling = FactoryBot.create(:user)
        expect(ability).not_to be_able_to(:manage, sibling)
      end
    end

  end

  context "uk user" do
    let(:user) do
      FactoryBot.create(:uk_user)
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
  
    let(:subscription) { FactoryBot.create(:subscription) }
    let(:user) { subscription.user }

    let(:ability) { Ability.new(user) }

    it "has a valid subscription" do
      expect(user.subscriber?).to be_truthy
    end

    it "should be able to read an article" do
      article = FactoryBot.create(:article)
      expect(ability).to be_able_to(:read, article)
    end

    it "should not be able to manage an article" do
      article = FactoryBot.create(:article)
      expect(ability).not_to be_able_to(:manage, article)
    end

    it "should not be able to manage a push registration" do
      push_registration = FactoryBot.create(:push_registration)
      expect(ability).not_to be_able_to(:manage, push_registration)
    end

    it "should not be able to manage a payment notifications" do
      payment_notification = FactoryBot.create(:payment_notification)
      expect(ability).not_to be_able_to(:manage, payment_notification)
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

    it "with two subscriptions, has the correct expiry date" do
      subscription.duration = 3
      subscription.price_paid = 91
      user.subscriptions.new(valid_from: (user.last_subscription.try(:expiry_date) or DateTime.now), duration: 3, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(2)
        total_months = 0
        user.subscriptions.each do |s|
          if s.is_current?
            total_months += s.duration
          end
        end
        expect(user.subscriptions.first.valid_from + total_months.months).to eq(user.expiry_date)
        expect(user.expiry_date_paper_only).to be_nil
        expect(user.expiry_date_paper_copy).to be_nil
      end
    end

    it "with two subscriptions, the first refunded, has the correct expiry date" do
      subscription.duration = 3
      subscription.price_paid = 91
      user.subscriptions.new(valid_from: (user.last_subscription.try(:expiry_date) or DateTime.now), duration: 3, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        subscription.refunded_on = DateTime.now
        subscription.expire_subscription
        expect(user.subscriptions.count).to eq(2)
        # TODO: fix this in the subscription.rb model
        # expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date)
        expect(user.expiry_date_paper_only).to be_nil
        expect(user.expiry_date_paper_copy).to be_nil
      end
    end

    it "with two subscriptions, the second refunded, has the correct expiry date" do
      subscription.duration = 3
      user.subscriptions.new(valid_from: (user.last_subscription.try(:expiry_date) or DateTime.now), duration: 3, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        user.subscriptions.last.refunded_on = DateTime.now
        user.subscriptions.last.expire_subscription
        expect(user.subscriptions.count).to eq(2)
        expect(user.subscriptions.first.purchase_date + (user.subscriptions.first.duration).months).to eq(user.expiry_date)
        expect(user.expiry_date_paper_only).to be_nil
        expect(user.expiry_date_paper_copy).to be_nil
      end
    end

    it "with two subscriptions, the first digital, the second paper only, has the correct expiry date and paper expiry date" do
      subscription.duration = 12
      user.subscriptions.new(valid_from: DateTime.now, duration: 12, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(2)
        expect(user.subscriptions.first.purchase_date + (user.subscriptions.first.duration).months).to eq(user.expiry_date)
        expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_truthy
      end
    end

    it "with two subscriptions, the first an expired digital, the second paper only, has the correct expiry date and paper expiry date" do
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 18.months
      subscription.purchase_date = DateTime.now - 18.months
      subscription.save
      user.subscriptions.new(valid_from: DateTime.now, duration: 12, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(2)
        expect(user.subscriptions.last.purchase_date + 3.months).to eq(user.expiry_date)
        expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_truthy
      end
    end

    it "with two subscriptions, the first a current digital, the second an expired paper only, has the correct expiry date and paper expiry date" do
      subscription.duration = 12
      subscription.save
      user.subscriptions.new(valid_from: DateTime.now - 18.months, duration: 12, purchase_date: DateTime.now - 18.months, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(2)
        expect(user.subscriptions.first.purchase_date + (user.subscriptions.first.duration).months).to eq(user.expiry_date)
        expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_falsey
        expect(user.has_paper_only?).to be_falsey
      end
    end

    it "with three subscriptions, expired digital, expired paper only, new paper_only, has the correct expiry date and paper expiry date" do
      # Expired digital
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 18.months
      subscription.purchase_date = DateTime.now - 18.months
      subscription.save
      # Expired paper only
      user.subscriptions.new(valid_from: DateTime.now - 24.months, duration: 12, purchase_date: DateTime.now - 24.months, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      # New paper only
      user.subscriptions.new(valid_from: DateTime.now, duration: 12, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(3)
        expect(user.subscriptions.last.purchase_date + 3.months).to eq(user.expiry_date)
        expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_truthy
      end
    end

    it "with three subscriptions, expired digital, expired paper only, new paper and digital, has the correct expiry date and paper expiry date" do
      # Expired digital
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 18.months
      subscription.purchase_date = DateTime.now - 18.months
      subscription.save
      # Expired paper only
      user.subscriptions.new(valid_from: DateTime.now - 24.months, duration: 12, purchase_date: DateTime.now - 24.months, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      # New paper and digital
      user.subscriptions.new(valid_from: DateTime.now, duration: 6, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(3)
        expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date)
        expect(user.subscriptions.second.purchase_date + (user.subscriptions.second.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_falsey
      end
    end

    it "with three subscriptions, current digital, expired paper only, new paper only, has the correct expiry date and paper expiry date" do
      # Current digital
      subscription.duration = 12
      subscription.valid_from = DateTime.now
      subscription.purchase_date = DateTime.now
      subscription.save
      # Expired paper only
      user.subscriptions.new(valid_from: DateTime.now - 24.months, duration: 12, purchase_date: DateTime.now - 24.months, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      # New paper only
      user.subscriptions.new(valid_from: DateTime.now, duration: 6, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(3)
        expect(user.subscriptions.first.purchase_date + (user.subscriptions.first.duration).months).to eq(user.expiry_date)
        expect(user.subscriptions.last.purchase_date + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_truthy
      end
    end

    it "with three subscriptions, current digital, expired paper only, new paper only, has the correct expiry date and paper expiry date" do
      # Current digital
      subscription.duration = 12
      subscription.valid_from = DateTime.now
      subscription.purchase_date = DateTime.now
      subscription.save
      # Expired paper only
      user.subscriptions.new(valid_from: DateTime.now - 24.months, duration: 12, purchase_date: DateTime.now - 24.months, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      # New paper and digital
      user.subscriptions.new(valid_from: DateTime.now, duration: 6, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(3)
        expect(user.subscriptions.first.purchase_date + (user.subscriptions.first.duration).months).to eq(user.expiry_date)
        # TODO: Should add the first digital current sub with the last digital and paper duration
        # expect((user.subscriptions.first.purchase_date + (user.subscriptions.first.duration).months) + (user.subscriptions.last.duration).months).to eq(user.expiry_date)
        expect(user.subscriptions.second.purchase_date + (user.subscriptions.second.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_falsey
      end
    end

    it "with three subscriptions, expired digital, current paper only, new paper only, has the correct expiry date and paper expiry date" do
      # Expired digital
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 18.months
      subscription.purchase_date = DateTime.now - 18.months
      subscription.save
      # Current paper only
      user.subscriptions.new(valid_from: DateTime.now, duration: 12, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      # New paper only
      user.subscriptions.new(valid_from: user.subscriptions.second.expiry_date_paper_only, duration: 6, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(3)
        expect(user.subscriptions.last.valid_from + 3.months).to eq(user.expiry_date)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_truthy
      end
    end

    it "with three subscriptions, expired digital, current paper only, new paper and digital, has the correct expiry date and paper expiry date" do
      # Expired digital
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 18.months
      subscription.purchase_date = DateTime.now - 18.months
      subscription.save
      # Current paper only
      user.subscriptions.new(valid_from: DateTime.now, duration: 12, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1, paper_only: 1)
      user.subscriptions.last.save
      # New paper and digital
      user.subscriptions.new(valid_from: user.subscriptions.second.expiry_date_paper_only, duration: 6, purchase_date: DateTime.now, paypal_payer_id: "aaa", paypal_profile_id: "bbb", price_paid: 91, paper_copy: 1)
      user.subscriptions.last.save
      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(3)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date)
        expect(user.subscriptions.second.valid_from + (user.subscriptions.second.duration).months).to eq(user.expiry_date_paper_only)
        expect(user.subscriptions.last.valid_from + (user.subscriptions.last.duration).months).to eq(user.expiry_date_paper_copy)
        expect(user.has_paper_copy?).to be_truthy
        expect(user.has_paper_only?).to be_truthy
      end
    end

    it "with a recurring subscription, returns is_recurring true" do
      # Recurring digital subscription
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 6.months
      subscription.purchase_date = DateTime.now - 6.months
      subscription.paypal_profile_id = 'fake_payer_id'
      subscription.save

      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(1)
        expect(user.is_recurring?).to be_truthy
      end
    end

    it "with a recurring subscription and failed payment notification, returns is_recurring false" do
      # Recurring digital subscription
      subscription.duration = 12
      subscription.valid_from = DateTime.now - 6.months
      subscription.purchase_date = DateTime.now - 6.months
      subscription.paypal_profile_id = 'fake_payer_id'
      subscription.save
      user.payment_notifications.new(transaction_type: 'recurring_payment_suspended_due_to_max_failed_payment')

      Timecop.freeze(2012,1,10,0,0,0) do
        expect(user.subscriptions.count).to eq(1)
        expect(user.is_recurring?).to be_falsey
      end
    end

  end

  context "manager" do

    let(:user) do
      FactoryBot.create(:manager_user)
    end

    let(:ability) { Ability.new(user) }

    it "should be able to read an article" do
      article = FactoryBot.create(:article)
      expect(ability).to be_able_to(:read, article)
    end

    it "should not be able to manage an article" do
      article = FactoryBot.create(:article)
      expect(ability).not_to be_able_to(:manage, article)
    end

    it "should not be able to manage a page" do
      page = FactoryBot.create(:page)
      expect(ability).not_to be_able_to(:manage, page)
    end

    it "should not be able to manage settings" do
      settings = Settings.get_all
      expect(ability).not_to be_able_to(:manage, settings)
    end

    it "should not be able to manage a push registration" do
      push_registration = FactoryBot.create(:push_registration)
      expect(ability).not_to be_able_to(:manage, push_registration)
    end

    it "should not be able to manage a payment notifications" do
      payment_notification = FactoryBot.create(:payment_notification)
      expect(ability).not_to be_able_to(:manage, payment_notification)
    end

    it "should be able to manage a user" do
      general_user = FactoryBot.create(:user)
      expect(ability).to be_able_to(:manage, general_user)
    end

    it "should be able to manage a subscription" do
      subscription = FactoryBot.create(:subscription)
      expect(ability).to be_able_to(:manage, subscription)
    end

    context "with three subscribers" do

      before(:each) do
        FactoryBot.create(:subscription)
        FactoryBot.create(:subscription)
        FactoryBot.create(:subscription)
        FactoryBot.create(:user)
        FactoryBot.create(:user)
        FactoryBot.create(:user)
      end

      it "should be able to download a users_csv" do
        User.update_admin_users_csv
        users_csv = CSV.parse(Settings.users_csv)
        # 1 header, 3 subscribers, 3 users
        expect(users_csv.count).to eq(7)
        expect(Settings.users_csv).to include(User.first.email)
        expect(Settings.users_csv).to include(User.last.email)
      end

      it "should be able to download a current_digital_subscribers_csv" do
        u = Subscription.first.user
        u.email_opt_in = "Y"
        u.postal_mailable = "Y"
        u.save
        u2 = Subscription.second.user
        u2.email_opt_in = "M"
        u2.postal_mailable = "R"
        u2.save

        User.update_current_digital_subscribers_csv
        current_digital_subscribers_csv = CSV.parse(Settings.current_digital_subscribers_csv)

        # 1 header, 2 subscribers with email_opt_in Y or M
        expect(current_digital_subscribers_csv.count).to eq(3)
        expect(Settings.current_digital_subscribers_csv).to include(u.email)
        expect(Settings.current_digital_subscribers_csv).to include(u2.email)
      end

      it "should be able to download a lapsed_digital_subscribers_csv" do
        u = Subscription.first.user
        u.email_opt_in = "Y"
        u.postal_mailable = "Y"
        u.digital_renewals = "Y"
        u.save
        u2 = Subscription.second.user
        u2.email_opt_in = "M"
        u2.postal_mailable = "R"
        u2.digital_renewals = "N"
        u2.save
        u3 = Subscription.third.user
        u3.email_opt_in = "Y"
        u3.save
        s = Subscription.first
        s.price_paid = 8800
        s.expire_subscription
        s.save
        s2 = Subscription.second
        s2.price_paid = 8800
        s2.expire_subscription
        s2.save

        User.update_lapsed_digital_subscribers_csv
        lapsed_digital_subscribers_csv = CSV.parse(Settings.lapsed_digital_subscribers_csv)

        # 1 header, 2 expired subscriptions with 1 digital renewals
        expect(lapsed_digital_subscribers_csv.count).to eq(2)
        expect(Settings.lapsed_digital_subscribers_csv).to include(u.email)
        expect(Settings.lapsed_digital_subscribers_csv).not_to include(u2.email)
        expect(Settings.lapsed_digital_subscribers_csv).not_to include(u3.email)
      end

      it "should be able to download a current_paper_subscribers_csv" do
        u = Subscription.first.user
        u.postal_mailable = "Y"
        u.save
        u2 = Subscription.second.user
        u2.postal_mailable = "R"
        u2.save
        u3 = Subscription.third.user
        u3.postal_mailable = "Y"
        u3.save
        s = Subscription.first
        s.price_paid = 8800
        s.paper_copy = true
        s.paper_only = true
        s.save
        s2 = Subscription.second
        s2.price_paid = 10000
        s2.paper_copy = true
        s2.save
        s3 = Subscription.third
        s3.price_paid = 10000
        s3.paper_copy = true
        s3.save
        s4 = FactoryBot.create(:paper_only_subscription)
        s4.paper_copy = true
        s4.save
        u4 = s4.user
        u4.institution = true
        u4.postal_mailable = "Y"
        u4.save

        User.update_current_paper_subscribers_csv
        current_paper_subscribers_csv = CSV.parse(Settings.current_paper_subscribers_csv)

        # 1 header, 3 current paper subscriptions, 1 institution
        expect(current_paper_subscribers_csv.count).to eq(4)
        expect(Settings.current_paper_subscribers_csv).to include(u.email)
        expect(Settings.current_paper_subscribers_csv).to_not include(u2.email)
        expect(Settings.current_paper_subscribers_csv).to include(u3.email)
        expect(Settings.current_paper_subscribers_csv).to include(u4.email)
        expect(Settings.current_paper_subscribers_csv).to include(',I,')
      end

      it "should be able to update subscriber stats" do
        # With a paper_only subscription
        FactoryBot.create(:paper_only_subscription)

        User.update_subscriber_stats

        expect(Settings.subscriber_stats).to be_truthy
        # TODO: don't double count digital trial as digital sub
        expect(Settings.subscriber_stats['subscribers_total']).to eq(5)
        expect(Settings.subscriber_stats['institutions']).to eq(0)
        expect(Settings.subscriber_stats['students']).to eq(0)
        expect(Settings.subscriber_stats['subscribers_digital']).to eq(4)
        expect(Settings.subscriber_stats['subscribers_paper_only']).to eq(1)
        expect(Settings.subscriber_stats['subscribers_paper_digital']).to eq(0)
        expect(Settings.subscriber_stats['last_updated']).to be_truthy
      end

    end

  end

end

