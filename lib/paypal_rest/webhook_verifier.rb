module PaypalRest
  class WebhookVerifier
    REQUIRED_HEADERS = %w[
      PAYPAL-AUTH-ALGO
      PAYPAL-CERT-URL
      PAYPAL-TRANSMISSION-ID
      PAYPAL-TRANSMISSION-SIG
      PAYPAL-TRANSMISSION-TIME
    ].freeze

    def initialize(headers:, payload:, client: Client.new, sandbox: PaypalConfiguration.sandbox?)
      @headers = headers
      @payload = payload
      @client = client
      @sandbox = sandbox
    end

    def valid?
      webhook_id = PaypalConfiguration.webhook_id(sandbox: @sandbox)
      raise PaypalConfiguration::ConfigurationError, "PayPal webhook ID is not configured." if webhook_id.blank? && Rails.env.production?
      return true if webhook_id.blank?

      response = @client.verify_webhook_signature(
        headers: required_headers,
        payload: @payload,
        webhook_id: webhook_id
      )
      response["verification_status"] == "SUCCESS"
    end

    private

    def required_headers
      REQUIRED_HEADERS.each_with_object({}) do |header_name, values|
        values[header_name] = @headers[header_name] || @headers["HTTP_#{header_name.tr('-', '_')}"]
      end
    end
  end
end
