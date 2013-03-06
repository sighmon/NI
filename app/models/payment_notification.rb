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
			# Ignore this. It's an instant payment that's been handled.
			logger.info "Express checkout IPN ping received. TXN_ID: #{transaction_id}"
		elsif params[:test_ipn] == "1"
			# Ignore test IPNs.
			logger.info "Test IPN ping received. TXN_ID: #{transaction_id}"
		elsif transaction_type == "cart"
			# Ignore this. It's an instant payment that's been handled.
			logger.info "Instant purchase IPN ping received. TXN_ID: #{transaction_id}"
		elsif transaction_type == "web_accept"
			# This is a ping from our web shop.
			logger.info "Web Accept IPN ping received. TXN_ID: #{transaction_id}"
		elsif transaction_type == "send_money"
			# This is someone manually sending us money.
			logger.info "Send Money IPN ping received. TXN_ID: #{transaction_id}"
		elsif params[:payment_type] == "echeck"
			# This is a PayPal echeck refund or payment
			logger.info "echeck IPN ping received. TXN_ID: #{transaction_id}"
		elsif status == "Refunded"
			# This is a refund made through the paypal interface
			logger.info "Refund IPN ping received. TXN_ID: #{transaction_id}"
		elsif transaction_type == "recurring_payment_profile_created"
			# PayPal letting us know that the profile was created successfully
			logger.info "Recurring payment profile created: #{params[:recurring_payment_id]}"
		else
			@user = User.find(self.user_id)

			# Test to see if it's a subscription renewal, or a subscription cancellation
			if status == "Completed" and transaction_type == "recurring_payment" and params[:profile_status] == "Active"
				# It's a recurring subscription debit
				# Find out how many months & update expiry_date
				# PayPal doesn't send us back the subscription :frequency, so we need to calculate that from initial recurring subscription
				months = @user.first_recurring_subscription(params[:recurring_payment_id]).duration
				# old hack method
				# months = params[:mc_gross].to_i / ( Settings.subscription_price / 100 )
				renew_subscription(months)
				logger.info "Subscription renewed for another #{months} months."

			elsif params[:profile_status] == "Cancelled" and transaction_type == "recurring_payment_profile_cancel"
				# It's a recurring subscription cancellation.
				if @user.subscription_valid?
					expire_recurring_subscriptions(@user)
					logger.info "Recurring subscriptions expired successfully."
					# send a special email saying cancelled through paypal.
					UserMailer.subscription_cancelled_via_paypal(user).deliver
				else
					logger.info "Subscription already cancelled."
				end
			else
				logger.info "Unkown transaction."
			end
		end		
	end

	def expire_recurring_subscriptions(user)
		all_subscriptions = user.recurring_subscriptions(params[:recurring_payment_id])
		all_subscriptions.each do |s|
			s.expire_subscription
			s.save
			logger.info "Refund for subscription id: #{s.id} is #{s.refund} cents."
			logger.info "Expired Subscription id: #{s.id} - cancel date: #{s.cancellation_date}"
		end
	end

	def renew_subscription(months)
        @subscription = Subscription.create(
        	:paypal_profile_id => params[:recurring_payment_id],
        	:paypal_payer_id => params[:payer_id],
        	:paypal_email => params[:payer_email],
        	:paypal_first_name => params[:first_name],
        	:paypal_last_name => params[:last_name],
        	:price_paid => (params[:mc_gross].to_i * 100), 
        	:user_id => @user.id, 
        	:valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), 
        	:duration => months, 
        	:purchase_date => DateTime.now
        )
        @subscription.save
    end

end
