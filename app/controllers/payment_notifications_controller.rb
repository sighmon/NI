class PaymentNotificationsController < ApplicationController
	
	protect_from_forgery except: [:create]

	def create
		payload = JSON.parse(request.raw_post)
		verifier = PaypalRest::WebhookVerifier.new(headers: request.headers, payload: payload)

		unless verifier.valid?
			render json: { success: false }, status: :unprocessable_entity
			return
		end

		PaypalRest::WebhookHandler.new(event: payload).process!
		render json: {success: true}
	rescue JSON::ParserError
		render json: { success: false }, status: :bad_request
	rescue PaypalConfiguration::ConfigurationError, PaypalRest::Error => e
		logger.warn "PayPal webhook rejected: #{e.message}"
		render json: { success: false }, status: :unprocessable_entity
	end

	private

	def payment_notification_params
		params.require(:payment_notification).permit(:params, :status, :transaction_id, :transaction_type, :user_id)
	end
	
end
