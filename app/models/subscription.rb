class Subscription < ActiveRecord::Base
  belongs_to :user
  attr_accessible :expiry_date, :user_id, :paypal_payer_id, :paypal_profile_id, :paypal_first_name, :paypal_last_name, :refund
end
