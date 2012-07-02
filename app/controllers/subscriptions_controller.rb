class SubscriptionsController < ApplicationController
	# Cancan authorisation
    load_and_authorize_resource

    def new

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

    # TOFIX: Not sure how to update subscription expiry_date on user edit page
    # def update
    #     @subscription = current_user.subscription
    #     @subscription.update_attributes(params[:expiry_date])

    #     respond_to do |format|
    #         if @subscription.save
    #             format.html { redirect_to current_user, notice: 'Subscription date updated.' }
    #             format.json { render json: @subscription, status: :created, location: @subscription }
    #         else
    #             format.html { redirect_to current_user, notice: "Couldn't update your subscription date, sorry." }
    #             format.json { render json: @subscription.errors, status: :unprocessable_entity }
    #         end
    #     end
    # end
end
