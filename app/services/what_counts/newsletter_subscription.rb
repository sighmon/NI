require "base64"

module WhatCounts
  class NewsletterSubscription
    ACCEPT_HEADER = "application/vnd.whatcounts-v1+json".freeze
    CONTENT_TYPE_HEADER = "application/json".freeze
    DUPLICATE_SUBSCRIPTION_ERROR = "Cannot insert duplicate subscription".freeze
    GENERIC_ERROR_MESSAGE = "We could not process your newsletter signup right now. Please try again later.".freeze
    INVALID_EMAIL_MESSAGE = "Please enter a valid email address.".freeze
    SUCCESS_MESSAGE = "Thanks for signing up to the newsletter.".freeze
    DUPLICATE_SUCCESS_MESSAGE = "That email is already subscribed to the newsletter.".freeze
    CONFIGURATION_ERROR_MESSAGE = "Newsletter signup is not configured yet.".freeze

    Result = Struct.new(:success, :message, :status_code, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(email:)
      @email = email.to_s.strip
    end

    def call
      return failure(CONFIGURATION_ERROR_MESSAGE) if missing_configuration?

      response = HTTParty.post(
        request_url,
        headers: headers,
        body: payload.to_json,
        timeout: 10
      )

      return success(SUCCESS_MESSAGE, response.code) if response.code.to_i == 200

      error_message = extract_error_message(response)

      if duplicate_subscription?(error_message)
        success(DUPLICATE_SUCCESS_MESSAGE, response.code)
      else
        Rails.logger.error(
          "WhatCounts newsletter signup failed: status=#{response.code} error=#{error_message.presence || response.body}"
        )
        failure(friendly_error_message(error_message), response.code)
      end
    rescue StandardError => e
      Rails.logger.error("WhatCounts newsletter signup exception: #{e.class}: #{e.message}")
      failure(GENERIC_ERROR_MESSAGE)
    end

    private

    attr_reader :email

    def success(message, status_code = nil)
      Result.new(success: true, message: message, status_code: status_code)
    end

    def failure(message, status_code = nil)
      Result.new(success: false, message: message, status_code: status_code)
    end

    def request_url
      "#{base_url}/rest/lists/#{list_id}?format=2&duplicates=0"
    end

    def headers
      request_headers = {
        "Authorization" => "Basic #{Base64.strict_encode64("#{realm_name}:#{api_password}")}",
        "Accept" => ACCEPT_HEADER,
        "Content-Type" => CONTENT_TYPE_HEADER
      }

      if api_client_name.present? && api_client_auth_code.present?
        request_headers["x-api-key"] = Base64.strict_encode64("#{api_client_name}:#{api_client_auth_code}")
      end

      request_headers
    end

    def payload
      request_payload = {
        subscriberId: 0,
        email: email,
        firstName: inferred_first_name
      }

      request_payload[:customerKey] = customer_key if customer_key.present?
      request_payload
    end

    def inferred_first_name
      local_part = email.split("@").first.to_s
      inferred_name = local_part.tr("._-", " ").squish.titleize
      inferred_name.presence || "Newsletter Subscriber"
    end

    def extract_error_message(response)
      parsed_response = response.parsed_response

      case parsed_response
      when Hash
        parsed_response["error"].to_s
      when String
        parsed_response
      else
        response.body.to_s
      end
    rescue StandardError
      response.body.to_s
    end

    def duplicate_subscription?(error_message)
      error_message.to_s.include?(DUPLICATE_SUBSCRIPTION_ERROR)
    end

    def friendly_error_message(error_message)
      return INVALID_EMAIL_MESSAGE if invalid_email_error?(error_message)

      GENERIC_ERROR_MESSAGE
    end

    def invalid_email_error?(error_message)
      error_message.to_s.downcase.include?("email")
    end

    def missing_configuration?
      [base_url, realm_name, api_password, list_id].any?(&:blank?)
    end

    def base_url
      ENV["WHATCOUNTS_BASE_URL"].to_s.sub(%r{/*\z}, "")
    end

    def realm_name
      ENV["WHATCOUNTS_REALM_NAME"].to_s
    end

    def api_password
      ENV["WHATCOUNTS_API_PASSWORD"].to_s
    end

    def list_id
      ENV["WHATCOUNTS_LIST_ID"].to_s
    end

    def customer_key
      ENV["WHATCOUNTS_CUSTOMER_KEY"].to_s
    end

    def api_client_name
      ENV["WHATCOUNTS_API_CLIENT_NAME"].to_s
    end

    def api_client_auth_code
      ENV["WHATCOUNTS_API_CLIENT_AUTH_CODE"].to_s
    end
  end
end
