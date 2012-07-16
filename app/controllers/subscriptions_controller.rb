class SubscriptionsController < ApplicationController
	# Cancan authorisation
    load_and_authorize_resource

    # TODO: rescue from trying to subscribe without signing in/up.

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

    def retrieve_paypal_express_details(token)
        details = EXPRESS_GATEWAY.details_for(token)
        # logger.info details.params
        session[:express_payer_id] = details.payer_id
        session[:express_first_name] = details.params["first_name"]
        session[:express_last_name] = details.params["last_name"]
    end

    def new

        @express_token = params[:token]
        @express_payer_id = params[:PayerID]

        @has_token = not(@express_token.blank? or @express_payer_id.blank?)

        if @has_token
            retrieve_paypal_express_details(@express_token)
            session[:express_token] = @express_token
        else
            
        end

    end

    def create

        months = session[:express_purchase_subscription_duration]

        @subscription = current_user.subscription

        if session[:express_autodebit]
            # It's an autodebit, so set that up
            # 1. setup autodebit
            ppr = PayPal::Recurring.new({
              :token       => session[:express_token],
              :payer_id    => session[:express_payer_id],
              :amount      => (session[:express_purchase_price] / 100),
              :currency    => 'AUD',
              :description => "#{session[:express_purchase_subscription_duration]} monthly automatic-debit subscription to NI"
            })
            response_request = ppr.request_payment

            # 2. create profile & save recurring profile token
            ppr = PayPal::Recurring.new({
              :token       => session[:express_token],
              :payer_id    => session[:express_payer_id],
              :amount      => (session[:express_purchase_price] / 100),
              :currency    => 'AUD',
              :description => "#{session[:express_purchase_subscription_duration]} monthly automatic-debit subscription to NI"
              :frequency   => session[:express_purchase_subscription_duration],
              :period      => :monthly,
              :reference   => "NI ID #{current_user.id}",
              :start_at    => Time.zone.now,
            })

            response_create = ppr.create_recurring_profile
            # TODO: Save response_create.profile_id to @subscription model
            # puts response_create.profile_id

            if response_request.approved? and response_request.completed? and not(response_create.profile_id.blank?)
                # If successful, update the user's subscription date.
                update_subscription_expiry_date
            end
        else
            # It's a single purchase so make the PayPal purchase
            response = EXPRESS_GATEWAY.purchase(session[:express_purchase_price], express_purchase_options)
            if response.success?
                # If successful, update the user's subscription date.
                update_subscription_expiry_date
            end
        end

        # TODO: implement automatically purchase the current issue

    	respond_to do |format|
            if response.success? and @subscription.save
                format.html { redirect_to current_user, notice: 'Subscription was successfully purchased.' }
                format.json { render json: @subscription, status: :created, location: @subscription }
            else
                format.html { redirect_to current_user, notice: "Couldn't subscribe, sorry." }
                format.json { render json: @subscription.errors, status: :unprocessable_entity }
            end
        end
    end

    private

    def update_subscription_expiry_date
        if @subscription.nil?
                    @subscription = Subscription.create(:user_id => current_user.id, :expiry_date => Date.today + months.months)
        elsif @subscription.expiry_date < DateTime.now
            @subscription.expiry_date = Date.today + months.months
        else
            @subscription.expiry_date += months.months
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
