class PaymentNotification < ActiveRecord::Base
	
	attr_accessor :params

	belongs_to :user
	# serialize :params
	after_create :update_subscription

	private

	def update_subscription
		# Log for testing.
		# logger.info params

		# TODO: Check that the ipn_url is working on real server.

		if transaction_type == "express_checkout"
			# Ignore this. It's an instant payment that's been handled.
			logger.info "Express checkout IPN ping received. TXN_ID: #{transaction_id}"
		elsif params["test_ipn"] == "1"
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
		elsif params["payment_type"] == "echeck"
			# This is a PayPal echeck refund or payment
			logger.info "echeck IPN ping received. TXN_ID: #{transaction_id}"
		elsif status == "Refunded"
			# This is a refund made through the paypal interface
			logger.info "Refund IPN ping received. TXN_ID: #{transaction_id}"
		elsif transaction_type == "recurring_payment_profile_created"
			# PayPal letting us know that the profile was created successfully
			if User.find(self.user_id).try(:first_recurring_subscription,params["recurring_payment_id"])
				logger.info "Recurring payment profile created: #{params["recurring_payment_id"]}"
			else
				logger.warn "Did not find matching subscription for 'recurring_payment_profile_created' IPN: #{params["recurring_payment_id"]}"
			end
		else
			@user = User.find(self.user_id)

			# Test to see if it's a subscription renewal, or a subscription cancellation
			if status == "Completed" and transaction_type == "recurring_payment" and params["profile_status"] == "Active"
				# It's a recurring subscription debit
				# Find out how many months & update expiry_date
				# PayPal doesn't send us back the subscription :frequency, so we need to calculate that from initial recurring subscription
				first_recurring_subscription = @user.first_recurring_subscription(params["recurring_payment_id"])
				# old hack method
				# months = params[:mc_gross].to_i / ( Settings.subscription_price / 100 )
				renew_subscription(first_recurring_subscription)
				logger.info "Subscription renewed for another #{first_recurring_subscription.duration} months."

			elsif status == "Completed" and transaction_type == "recurring_payment_outstanding_payment" and params["profile_status"] == "Suspended"
				# It's a suspended recurring subscription that's been reactivated
				first_recurring_subscription = @user.first_recurring_subscription(params["recurring_payment_id"])
				# logger.info first_recurring_subscription
				renew_subscription(first_recurring_subscription)
				logger.info "Suspended subscription renewed for another #{first_recurring_subscription.duration} months."
				# send the admin an email to reactivate the profile
				begin
          UserMailer.subscription_recurring_payment_outstanding_payment(@user).deliver
        rescue Exception
          logger.error "500 - Email server is down..."
        end

			elsif params["profile_status"] == "Cancelled" and transaction_type == "recurring_payment_profile_cancel"
				# It's a recurring subscription cancellation.
				if @user.subscription_valid?
					expire_recurring_subscriptions(@user)
					logger.info "Recurring subscriptions expired successfully."
					# send a special email saying cancelled through paypal.
					begin
            UserMailer.subscription_cancelled_via_paypal(@user).deliver
          rescue Exception
            logger.error "500 - Email server is down..."
          end
				else
					logger.info "Subscription already cancelled."
				end
			elsif transaction_type == "recurring_payment_skipped"
				# TODO: handle skipped payment - make a note displayable to Admins?
				logger.info "PAYMENT SKIPPED"
				# logger.info params
			elsif transaction_type == "recurring_payment_suspended" || transaction_type == "recurring_payment_suspended_due_to_max_failed_payment"
				# TODO: handle suspended payment - make a note displayable to Admins?
				logger.info "PAYMENT SUSPENDED"
				# logger.info params
			else
				logger.info "Unknown transaction."
			end
		end		
	end

	def expire_recurring_subscriptions(user)
		all_subscriptions = user.recurring_subscriptions(params["recurring_payment_id"])
		all_subscriptions.each do |s|
			s.expire_subscription
			s.save
			logger.info "Refund for subscription id: #{s.id} is #{s.refund} cents."
			logger.info "Expired Subscription id: #{s.id} - cancel date: #{s.cancellation_date}"
		end
	end

	def renew_subscription(first_recurring_subscription)
		@subscription = Subscription.create(
			:paypal_profile_id => params["recurring_payment_id"],
			:paypal_payer_id => params["payer_id"],
			:paypal_email => params["payer_email"],
			:paypal_first_name => params["first_name"],
			:paypal_last_name => params["last_name"],
			:price_paid => (params["mc_gross"].to_i * 100), 
			:user_id => @user.id, 
			:valid_from => (@user.last_subscription.try("expiry_date") or DateTime.now), 
			:duration => first_recurring_subscription.duration,
			:paper_copy => first_recurring_subscription.paper_copy,
			:purchase_date => DateTime.now
		)
		if @subscription.save
			logger.info "subscription save successful"
		else
			logger.error "subscription save unsuccessful"
		end
	end

end
