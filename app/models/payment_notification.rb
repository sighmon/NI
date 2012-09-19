class PaymentNotification < ActiveRecord::Base
	attr_accessible :params, :status, :transaction_id, :transaction_type, :user_id
	belongs_to :user
	serialize :params
	after_create :update_subscription

private
	def update_subscription
		# Log for testing.
		# logger.info params

		# TODO: Check that the ipn_url is working on real server.

		# Test to see if it's a subscription renewal, or a subscription cancellation
		if status == "Completed" and transaction_type == "subscr_payment" and params[:recurring] == 1
			# It's a recurring subscription debit
			# Find out how many months & update expiry_date
			renew_subscription(params[:period3])

		elsif status == "Completed" and transaction_type == "subscr_cancel"
			calculate_refund
			expire_subscription
			# send email
			UserMailer.subscription_cancellation(user).deliver
		end
	end

	def calculate_refund
        user.subscription.refund = (user.subscription.expiry_date - Time.now) / 2592000
        user.subscription.save
        # logger.warn "Refund of #{user.subscription.refund} months due."
    end

	def expire_subscription
	    if user.subscription.nil?
	        # do nothing
	    elsif user.subscription.expiry_date > DateTime.now
	        user.subscription.expiry_date = Date.today - 1
	        user.subscription.save
	    end
	end

	def renew_subscription(months)
        if user.subscription.nil?
            user.subscription = Subscription.create(:user_id => user.id, :expiry_date => Date.today + months.months)
        elsif user.subscription.expiry_date < DateTime.now
            user.subscription.expiry_date = Date.today + months.months
        else
            user.subscription.expiry_date += months.months
        end
        user.subscription.save
    end

end
