class SubscriptionsController < ApplicationController
	# Cancan authorisation
    load_and_authorize_resource

    def new

    end

    def create
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
end
