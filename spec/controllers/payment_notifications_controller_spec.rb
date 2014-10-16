require 'spec_helper'

describe PaymentNotificationsController, :type => :controller do
  context "with a recurring subscribed user" do
    let(:user) do
      FactoryGirl.create(:subscription, paypal_profile_id: "RECURRING_PAYMENT_ID").user
    end

    describe "PUT create" do
      it "creates a subscription with a valid recurring IPN" do
        valid_params = {
          "amount"=>"29.00",
          "initial_payment_amount"=>"0.00",
          "profile_status"=>"Active",
          "payer_id"=>"PAYER_ID",
          "product_type"=>"1",
          "ipn_track_id"=>"IPN_TRACK_ID",
          "outstanding_balance"=>"0.00",
          "shipping"=>"0.00",
          "charset"=>"UTF-8",
          "period_type"=>" Regular",
          "payment_gross"=>"",
          "currency_code"=>"AUD",
          "verify_sign"=>"VERIFY_SIGN",
          "payment_cycle"=>"every 3 Months",
          "txn_type"=>"recurring_payment",
          "receiver_id"=>"RECEIVER_ID",
          "payment_fee"=>"",
          "mc_currency"=>"AUD",
          "transaction_subject"=>
            "3 monthly automatic-debit for both a Digital and Paper subscription to New Internationalist Magazine.",
          "protection_eligibility"=>"Ineligible",
          "payer_status"=>"verified",
          "first_name"=>"FIRST_NAME",
          "product_name"=>
            "3 monthly automatic-debit for both a Digital and Paper subscription to New Internationalist Magazine.",
          "amount_per_cycle"=>"29.00",
          "mc_gross"=>"29.00",
          "payment_date"=>"03:42:26 Jul 24, 2013 PDT",
          "rp_invoice_id"=>user.id,
          "payment_status"=>"Completed",
          "business"=>"business@example.com",
          "last_name"=>"LAST_NAME",
          "txn_id"=>"TRANSACTION_ID",
          "mc_fee"=>"1.00",
          "time_created"=>"21:06:28 Apr 23, 2013 PDT",
          "resend"=>"true",
          "payment_type"=>"instant",
          "notify_version"=>"3.7",
          "recurring_payment_id"=>"RECURRING_PAYMENT_ID",
          "payer_email"=>user.email,
          "receiver_email"=>"receiver_email@example.com",
          "next_payment_date"=>"03:00:00 Oct 24, 2013 PDT",
          "tax"=>"0.00",
          "residence_country"=>"AU",
          "action"=>"create",
          "controller"=>"payment_notifications"
        } 
        expect {
          post :create, valid_params 
        }.to change(Subscription, :count).by(1)
      end
    end

  end
 
  context "with an unsubscribed user" do
    let(:user) do
      FactoryGirl.create(:user)      
    end    

    describe "PUT create" do

      it "ignores a valid recurring subscription IPN" do
        valid_params = { 
          "payment_cycle"=>"every 3 Months",
          "txn_type"=>"recurring_payment_profile_created",
          "last_name"=>"LAST_NAME",
          "next_payment_date"=>"03:00:00 Jul 24, 2013 PDT",
          "residence_country"=>"AU",
          "initial_payment_amount"=>"0.00",
          "rp_invoice_id"=>user.id,
          "currency_code"=>"AUD",
          "time_created"=>"21:06:28 Apr 23, 2013 PDT",
          "verify_sign"=>"VERIFY_SIGN",
          "period_type"=>" Regular",
          "payer_status"=>"verified",
          "tax"=>"0.00",
          "payer_email"=>user.email,
          "first_name"=>"FIRST_NAME",
          "receiver_email"=>"ouremail@example.com",
          "payer_id"=>"PAYER_ID",
          "product_type"=>"1",
          "shipping"=>"0.00",
          "amount_per_cycle"=>"29.00",
          "profile_status"=>"Active",
          "charset"=>"UTF-8",
          "notify_version"=>"3.7",
          "amount"=>"29.00",
          "outstanding_balance"=>"0.00",
          "recurring_payment_id"=>"RECURRING_PAYMENT_ID",
          "product_name"=>
            "3 monthly automatic-debit for both a Digital and Paper subscription to New Internationalist Magazine.",
          "ipn_track_id"=>"IPN_TRACK_ID",
          "action"=>"create",
          "controller"=>"payment_notifications"
        }
        expect {
          post :create, valid_params 
        }.to change(Subscription, :count).by(0)

      end

    end

  end

end
