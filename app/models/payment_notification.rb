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

		if transaction_type == "express_checkout"
			# TODO: Implement handling this.
			logger.info "Express checkout IPN ping received. TXN_ID: #{transaction_id}"
		elsif transaction_type == "recurring_payment_profile_created"
			# TODO: Do we need to do anything with this?
			logger.info "Recurring payment profile created: #{params[:recurring_payment_id]}"
		else
			@user = User.find(self.user_id)

			# Test to see if it's a subscription renewal, or a subscription cancellation
			if status == "Completed" and transaction_type == "subscr_payment" and params[:recurring] == "1"
				# It's a recurring subscription debit
				# Find out how many months & update expiry_date
				renew_subscription(params[:period3])

			elsif params[:profile_status] == "Cancelled" and transaction_type == "recurring_payment_profile_cancel"
				if @user.subscription_valid?
					calculate_refund
					expire_subscription
					# send email
					UserMailer.subscription_cancellation(user).deliver
				else
					logger.info "Subscription already cancelled."
				end
			else
				logger.info "Unkown transaction."
			end
		end		
	end

	def calculate_refund
		@subscription = @user.recurring_subscription
		# TODO: Fix the following line so it takes into account all of the IPN subscriptions.
        @subscription.calculate_refund
        @subscription.save
        # logger.info "Refund of #{@subscription.refund} months due."
        # logger.warn "Refund of #{user.subscription.refund} months due."
    end

	def expire_subscription
		@subscription = @user.recurring_subscription
	    @subscription.cancellation_date = DateTime.now
	    logger.info "Subscription expired successfully, cancelled date: #{@subscription.cancellation_date}"
	    @subscription.save
	end

	def renew_subscription(months)
        @subscription = Subscription.create(:paypal_profile_id => transaction_id, :price_paid => params[:mc_gross], :user_id => @user.id, :valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => months, :purchase_date => DateTime.now)
        @subscription.save
    end

end
