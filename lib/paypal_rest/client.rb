require "json"

module PaypalRest
  class Error < StandardError
    attr_reader :status, :details

    def initialize(message, status: nil, details: nil)
      super(message)
      @status = status
      @details = details
    end
  end

  class Client
    include HTTParty

    DEFAULT_TIMEOUT = 20

    def initialize(sandbox: PaypalConfiguration.sandbox?)
      @sandbox = sandbox
      @base_url = PaypalConfiguration.base_url(sandbox: sandbox)
      @access_token = nil
    end

    def create_order(payload)
      request(:post, "/v2/checkout/orders", body: payload, prefer_representation: true)
    end

    def capture_order(order_id)
      request(:post, "/v2/checkout/orders/#{order_id}/capture", body: {}, prefer_representation: true)
    end

    def create_product(payload)
      request(:post, "/v1/catalogs/products", body: payload, prefer_representation: true)
    end

    def create_plan(payload)
      request(:post, "/v1/billing/plans", body: payload, prefer_representation: true)
    end

    def show_plan(plan_id)
      request(:get, "/v1/billing/plans/#{plan_id}")
    end

    def activate_plan(plan_id)
      request(:post, "/v1/billing/plans/#{plan_id}/activate", body: {})
    end

    def create_subscription(payload)
      request(:post, "/v1/billing/subscriptions", body: payload, prefer_representation: true)
    end

    def show_subscription(subscription_id)
      request(:get, "/v1/billing/subscriptions/#{subscription_id}")
    end

    def cancel_subscription(subscription_id, reason:)
      request(:post, "/v1/billing/subscriptions/#{subscription_id}/cancel", body: { reason: reason })
    end

    def verify_webhook_signature(headers:, payload:, webhook_id:)
      request(
        :post,
        "/v1/notifications/verify-webhook-signature",
        body: {
          auth_algo: headers.fetch("PAYPAL-AUTH-ALGO"),
          cert_url: headers.fetch("PAYPAL-CERT-URL"),
          transmission_id: headers.fetch("PAYPAL-TRANSMISSION-ID"),
          transmission_sig: headers.fetch("PAYPAL-TRANSMISSION-SIG"),
          transmission_time: headers.fetch("PAYPAL-TRANSMISSION-TIME"),
          webhook_id: webhook_id,
          webhook_event: payload
        }
      )
    end

    private

    def access_token
      return @access_token if @access_token.present?

      response = self.class.post(
        "#{@base_url}/v1/oauth2/token",
        basic_auth: {
          username: PaypalConfiguration.client_id(sandbox: @sandbox),
          password: PaypalConfiguration.secret(sandbox: @sandbox)
        },
        headers: {
          "Accept" => "application/json",
          "Accept-Language" => "en_US",
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        body: "grant_type=client_credentials",
        timeout: DEFAULT_TIMEOUT
      )

      parsed = parse_response(response)
      unless response.success?
        raise Error.new(error_message(parsed), status: response.code, details: parsed)
      end

      @access_token = parsed.fetch("access_token")
    end

    def request(method, path, body: nil, headers: {}, prefer_representation: false)
      request_headers = {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      }.merge(headers)
      request_headers["Prefer"] = "return=representation" if prefer_representation

      response = self.class.public_send(
        method,
        "#{@base_url}#{path}",
        headers: request_headers,
        body: body.to_json,
        timeout: DEFAULT_TIMEOUT
      )

      parsed = parse_response(response)
      unless response.success?
        raise Error.new(error_message(parsed), status: response.code, details: parsed)
      end

      parsed
    end

    def parse_response(response)
      parsed = response.parsed_response
      return parsed if parsed.is_a?(Hash) || parsed.is_a?(Array)
      return {} if response.body.blank?

      JSON.parse(response.body)
    rescue JSON::ParserError
      {}
    end

    def error_message(parsed)
      parsed["message"].presence || parsed.dig("details", 0, "description").presence || "PayPal API request failed"
    end
  end
end
