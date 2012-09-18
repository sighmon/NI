class PaymentNotification < ActiveRecord::Base
  attr_accessible :params, :status, :transaction_id, :transaction_type, :user_id
  belongs_to :user
  serialize :params
  after_create :expire_subscription

private
  def expire_subscription
  	logger.info params
    if status == "Completed" and transaction_type == "subscr_cancel"
      if user.subscription.nil?
	      # do nothing
	  elsif user.subscription.expiry_date > DateTime.now
	  	  # TODO: Check that the ipn_url is working on real server.
	      # calculate refund
	      user.subscription.refund = (user.subscription.expiry_date - Time.now) / 2592000
	      user.subscription.expiry_date = Date.today - 1
	      user.subscription.save
	      # send email
	      UserMailer.subscription_cancellation(user).deliver
	  end
    end
  end

end
