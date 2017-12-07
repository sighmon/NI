FactoryBot.define do

  factory :payment_notification do
    params do
      "payer_id" "fake_payer_id"
      "payment_status" "Completed"
      "txn_id" "fake_transaction_id"
      "txn_type" "recurring_payment"
      "recurring_payment_id" "fake_paypal_profile_id"
      "profile_status" "Active"
    end
    transaction_id "fake_transaction_id"
    transaction_type "recurring_payment"
    user
    status "Completed"
  end

end
