class PaymentNotificationsController < ApplicationController
	
	protect_from_forgery :except => [:create]

	def create
		# logger.info params
		
		# TOFIX: Hack to handle 'cart' instant payment notifications.
		if params[:txn_type] == "cart"
			params[:rp_invoice_id] == "1"
		end

		# TODO: using activemerchant to validate the IPN: https://go.developer.ebay.com/developers/community/blogs/saranyan/paypal-ipn-using-rails-3.1-and-active-merchant

		PaymentNotification.create!(:params => params, :user_id => params[:rp_invoice_id], :status => params[:payment_status], :transaction_id => params[:txn_id], :transaction_type => params[:txn_type] )
		render :nothing => true
	end

	private

	def payment_notification_params
		params.require(:payment_notification).permit(:params, :status, :transaction_id, :transaction_type, :user_id)
	end
	
end
