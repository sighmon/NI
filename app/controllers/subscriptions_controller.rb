class SubscriptionsController < ApplicationController
	# Cancan authorisation
    load_and_authorize_resource

    # TODO: rescue from trying to subscribe without signing in/up.

    def express
        # TODO: move the purchase price to an admin model

        case params[:duration]
        when "3"
            @express_purchase_price = 300
            @express_purchase_title = "3 Month Subscription"
        when "6"
            @express_purchase_price = 600
            @express_purchase_title = "6 Month Subscription"
        when "12"
            @express_purchase_price = 1200
            @express_purchase_title = "1 Year Subscription"
        end            

        session[:express_purchase_price] = @express_purchase_price
        session[:express_purchase_title] = @express_purchase_title

        response = EXPRESS_GATEWAY.setup_purchase(@express_purchase_price,
            :ip                 => request.remote_ip,
            :return_url         => new_subscription_url,
            :cancel_return_url  => new_subscription_url,
            :allow_note         => true,
            :items              => [{:name => @express_purchase_title, :quantity => 1, :description => "New Internationalist Magazine - subscription to the digital edition", :amount => @express_purchase_price}],
            :currency           => 'AUD'
        )
        redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
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

        case params[:duration]
        when "3"
            months = 3
        when "6"
            months = 6
        when "12"
            months = 12
        end

        @subscription = current_user.subscription

        if @subscription.nil?
            @subscription = Subscription.create(:user_id => current_user.id, :expiry_date => Date.today + months.months)
        elsif @subscription.expiry_date < DateTime.now
            @subscription.expiry_date = Date.today + months.months
        else
            @subscription.expiry_date += months.months
        end

        # TODO: implement automatically purchase the current issue

    	respond_to do |format|
            if @subscription.save
                format.html { redirect_to current_user, notice: 'Subscription was successfully purchased.' }
                format.json { render json: @subscription, status: :created, location: @subscription }
            else
                format.html { redirect_to current_user, notice: "Couldn't subscribe, sorry." }
                format.json { render json: @subscription.errors, status: :unprocessable_entity }
            end
        end
    end

    private

    def express_purchase_options
      {
        :ip         => request.remote_ip,
        :token      => session[:express_token],
        :payer_id   => session[:express_payer_id],
        :items      => [{:name => session[:express_purchase_title], :quantity => 1, :description => "New Internationalist Magazine - subscription to the digital edition", :amount => session[:express_purchase_price]}],
        :currency   => 'AUD'
      }
    end
end
