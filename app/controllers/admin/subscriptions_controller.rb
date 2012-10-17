class Admin::SubscriptionsController < ApplicationController
  # Cancan authorisation
  load_and_authorize_resource
  
  def update
  	@subscription.refunded_on = DateTime.now
  	if @subscription.save
  		redirect_to admin_user_path(@subscription.user_id), notice: "Subscription refund has been marked as paid."
  	else
  		redirect_to admin_user_path(@subscription.user_id), notice: "Sorry, couldn't update subscription refund date!"
  	end
  end

end
