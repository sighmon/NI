class SubscriptionsController < ApplicationController
	# Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to buy a subscription."
    end

    def express
        # TODO: move the purchase price to an admin model

        case params[:duration]
        when "3"
            @express_purchase_price = 300
            @express_purchase_subscription_duration = 3
        when "6"
            @express_purchase_price = 600
            @express_purchase_subscription_duration = 6
        when "12"
            @express_purchase_price = 1200
            @express_purchase_subscription_duration = 12
        end

        if params[:autodebit] == "1"
            @autodebit = true
            session[:express_autodebit] = @autodebit
        else
            @autodebit = false
            session[:express_autodebit] = @autodebit
        end

        session[:express_purchase_price] = @express_purchase_price
        session[:express_purchase_subscription_duration] = @express_purchase_subscription_duration

        if @autodebit
            # Autodebit setup
            ppr = PayPal::Recurring.new({
              :return_url   => new_subscription_url,
              :cancel_url   => new_subscription_url,
              :description  => "#{session[:express_purchase_subscription_duration]} monthly automatic-debit subscription to NI",
              :amount       => (session[:express_purchase_price] / 100),
              :currency     => 'AUD'
            })
            response = ppr.checkout
            redirect_to response.checkout_url if response.valid?
        else
            response = EXPRESS_GATEWAY.setup_purchase(@express_purchase_price,
                :ip                 => request.remote_ip,
                :return_url         => new_subscription_url,
                :cancel_return_url  => new_subscription_url,
                :allow_note         => true,
                :items              => [{:name => "#{session[:express_purchase_subscription_duration]} Month Subscription to NI", :quantity => 1, :description => "New Internationalist Magazine - subscription to the digital edition", :amount => session[:express_purchase_price]}],
                :currency           => 'AUD'
            )
            redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
        end
    end

    def new

        @user = current_user
        @express_token = params[:token]
        @express_payer_id = params[:PayerID]

        @has_token = not(@express_token.blank? or @express_payer_id.blank?)

        if @has_token
            retrieve_paypal_express_details(@express_token)
            session[:express_token] = @express_token
        else
            
        end

    end

    def edit
        @user = current_user
        @subscription = @user.subscription
        @cancel_subscription = true

        # TODO: cancel_recurring_subscription
        # TODO: make subscription expiry date today -1
    end

    def create

        payment_complete = false

        @subscription = current_user.subscription

        if session[:express_autodebit]
            # It's an autodebit, so set that up
            # 1. setup autodebit by requesting payment
            ppr = PayPal::Recurring.new({
              :token       => session[:express_token],
              :payer_id    => session[:express_payer_id],
              :amount      => (session[:express_purchase_price] / 100),
              :currency    => 'AUD',
              :description => "#{session[:express_purchase_subscription_duration]} monthly automatic-debit subscription to NI"
            })
            response_request = ppr.request_payment

            if response_request.approved? and response_request.completed?
                # 2. create profile & save recurring profile token
                ppr = PayPal::Recurring.new({
                  :token       => session[:express_token],
                  :payer_id    => session[:express_payer_id],
                  :amount      => (session[:express_purchase_price] / 100),
                  :currency    => 'AUD',
                  :description => "#{session[:express_purchase_subscription_duration]} monthly automatic-debit subscription to NI",
                  :frequency   => session[:express_purchase_subscription_duration],
                  :period      => :monthly,
                  :reference   => "NI UID #{current_user.id}",
                  :start_at    => Time.zone.now,
                  :failed      => 1,
                  :outstanding => :next_billing
                })

                response_create = ppr.create_recurring_profile
                if not(response_create.profile_id.blank?)
                    @subscription.paypal_profile_id = response_create.profile_id
                    # If successful, update the user's subscription date.
                    update_subscription_expiry_date

                    # TODO: Background task
                    # TODO: Check paypal recurring profile id still valid
                    # TODO: Setup future update_subscription_expiry_date

                    # Save the PayPal data to the @subscription model for receipts
                    save_paypal_data_to_subscription_model
                    payment_complete = true
                else
                    # Why didn't this work? Log it.
                    logger.warn "create_recurring_profile failed: #{response_create.params}"
                end
            else
                # Why didn't this work? Log it.
                logger.warn "request_payment failed: #{response_request.params}"
            end
        else
            # It's a single purchase so make the PayPal purchase
            response = EXPRESS_GATEWAY.purchase(session[:express_purchase_price], express_purchase_options)

            if response.success?
                # If successful, update the user's subscription date.
                update_subscription_expiry_date
                save_paypal_data_to_subscription_model
                payment_complete = true
            end
        end

        # TODO: implement automatically purchase the current issue

    	respond_to do |format|
            if payment_complete and @subscription.save
                UserMailer.subscription_confirmation(current_user).deliver
                format.html { redirect_to current_user, notice: 'Subscription was successfully purchased.' }
                format.json { render json: @subscription, status: :created, location: @subscription }
            else
                format.html { redirect_to current_user, notice: "Couldn't subscribe, sorry." }
                format.json { render json: @subscription.errors, status: :unprocessable_entity }
            end
        end
    end

    def update
        @user = current_user
        @subscription = @user.subscription
        cancel_complete = false

        if params[:cancel] == 'true'
            if !@subscription.paypal_profile_id.blank?
                # user has a recurring subscription
                if cancel_recurring_subscription
                    calculate_refund
                    expire_subscription
                    cancel_complete = true
                else 
                    redirect_to user_path(@user), notice: "Sorry, we couldn't cancel your PayPal recurring subscription, please try again later."
                end
            else
                # user has a normal subscription
                calculate_refund
                expire_subscription
                cancel_complete = true
            end
        else
            redirect_to user_path(@user)
        end

        if cancel_complete and @subscription.save
            # TODO: Send email to user & subscribe@newint.com.au asking whether they'd like a refund or not.
            redirect_to user_path(@user), notice: "Subscription was successfully cancelled."
        else
            redirect_to user_path(@user), notice: "Something went wrong in the last step, sorry."
        end

        # TODO: Check with pix that my above fix is okay.

        # respond_to do |format|
        #     if cancel_complete and @subscription.save
        #         format.html { redirect_to user_path(@user), notice: 'Subscription was successfully cancelled.' }
        #         format.json { render json: @subscription, status: :created, location: @subscription }
        #     else
        #         format.html { redirect_to user_path(@user), notice: "Something went wrong in the last step, sorry." }
        #         format.json { render json: @subscription.errors, status: :unprocessable_entity }
        #     end
        # end
    end

    def retrieve_paypal_express_details(token)
        details = EXPRESS_GATEWAY.details_for(token)
        # logger.info details.params
        session[:express_payer_id] = details.payer_id
        session[:express_email] = details.email
        session[:express_first_name] = details.params["first_name"]
        session[:express_last_name] = details.params["last_name"]
    end

private

    def cancel_recurring_subscription
        ppr = PayPal::Recurring.new(:profile_id => @subscription.paypal_profile_id)
        response = ppr.cancel
        if response.success?
            @subscription.paypal_profile_id = nil
            session[:express_autodebit] = false
            return true
        else
            return false
        end
    end

    def calculate_refund
        @subscription.refund = (@subscription.expiry_date - Time.now) / 2592000
        logger.warn "Refund of #{@subscription.refund} months due."
    end

    def save_paypal_data_to_subscription_model
        @subscription.paypal_payer_id = session[:express_payer_id]
        @subscription.paypal_email = session[:express_email]
        @subscription.paypal_first_name = session[:express_first_name]
        @subscription.paypal_last_name = session[:express_last_name]
        # @subscription.paypal_profile_id also saved for recurring payments earlier
    end

    def update_subscription_expiry_date
        months = session[:express_purchase_subscription_duration]
        if @subscription.nil?
            @subscription = Subscription.create(:user_id => current_user.id, :expiry_date => Date.today + months.months)
        elsif @subscription.expiry_date < DateTime.now
            @subscription.expiry_date = Date.today + months.months
        else
            @subscription.expiry_date += months.months
        end
    end

    def expire_subscription
        if @subscription.nil?
            # do nothing
        elsif @subscription.expiry_date > DateTime.now
            # TODO: write refund_due to @subscription model
            @subscription.expiry_date = Date.today - 1
        end
    end

    def express_purchase_options
      {
        :ip         => request.remote_ip,
        :token      => session[:express_token],
        :payer_id   => session[:express_payer_id],
        :items      => [{:name => "#{session[:express_purchase_subscription_duration]} Month Subscription to NI", :quantity => 1, :description => "New Internationalist Magazine - subscription to the digital edition", :amount => session[:express_purchase_price]}],
        :currency   => 'AUD'
      }
    end
end
