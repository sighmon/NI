class Admin::SubscriptionsController < ApplicationController
  # Cancan authorisation
  load_and_authorize_resource
  
  def update
    if @subscription.refunded_on.blank?
      # Mark subscription's refund date.
      @subscription.refunded_on = DateTime.now
    else
      # Admin wants to undo refund date.
      @subscription.refunded_on = nil
    end

  	if @subscription.save
  		redirect_to admin_user_path(@subscription.user_id), notice: "Subscription refund updated."
  	else
  		redirect_to admin_user_path(@subscription.user_id), notice: "Sorry, couldn't update subscription refund date!"
  	end
  end

end
