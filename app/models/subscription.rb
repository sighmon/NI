class Subscription < ActiveRecord::Base
  belongs_to :user
  attr_accessible :expiry_date, :user_id, :paypal_payer_id, :paypal_email, :paypal_profile_id, :paypal_first_name, :paypal_last_name, :refund

  def recurring?
  	return (not self.paypal_profile_id.nil?)
  end

end
