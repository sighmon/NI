require "base64"
require "json"
require "uri"

module WhatCounts
  class NewsletterSubscription
    ACCEPT_HEADER = "application/vnd.whatcounts-v1+json".freeze
    CONTENT_TYPE_HEADER = "application/json".freeze
    DUPLICATE_SUBSCRIPTION_ERROR = "Cannot insert duplicate subscription".freeze
    GENERIC_ERROR_MESSAGE = "We could not process your newsletter signup right now. Please try again later.".freeze
    INVALID_EMAIL_MESSAGE = "Please enter a valid email address.".freeze
    SUCCESS_MESSAGE = "Thanks for signing up to the newsletter.".freeze
    DUPLICATE_SUCCESS_MESSAGE = "That email is already subscribed to the newsletter.".freeze
    STATUS_SUBSCRIBED_MESSAGE = "Subscribed to the email newsletter.".freeze
    STATUS_UNSUBSCRIBED_MESSAGE = "Not subscribed to the email newsletter.".freeze
    UNSUBSCRIBE_SUCCESS_MESSAGE = "You have been unsubscribed from the newsletter.".freeze
    ALREADY_UNSUBSCRIBED_MESSAGE = "That email is not currently subscribed to the newsletter.".freeze
    CONFIGURATION_ERROR_MESSAGE = "Newsletter signup is not configured yet.".freeze

    Result = Struct.new(:success, :message, :status_code, :subscribed, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(email:, custom_is_subscriber: nil)
      @email = email.to_s.strip
      @custom_is_subscriber = custom_is_subscriber
    end

    def call
      subscribe
    end

    def status
      return failure(CONFIGURATION_ERROR_MESSAGE) if missing_configuration?

      lookup = lookup_subscribers
      return lookup if !lookup.success?

      if lookup.subscribed
        success(STATUS_SUBSCRIBED_MESSAGE, lookup.status_code, true)
      else
        success(STATUS_UNSUBSCRIBED_MESSAGE, lookup.status_code, false)
      end
    rescue StandardError => e
      Rails.logger.error("WhatCounts newsletter status exception: #{e.class}: #{e.message}")
      failure(GENERIC_ERROR_MESSAGE)
    end

    def subscribe
      return failure(CONFIGURATION_ERROR_MESSAGE) if missing_configuration?

      response = HTTParty.get(
        subscribe_url,
        timeout: 10
      )

      return success(SUCCESS_MESSAGE, response.code, true) if http_api_success?(response)

      error_message = extract_error_message(response)
      return success(DUPLICATE_SUCCESS_MESSAGE, response.code, true) if duplicate_subscription?(error_message)

      Rails.logger.error(
        "WhatCounts newsletter signup failed: status=#{response.code} error=#{error_message.presence || response.body}"
      )
      failure(friendly_error_message(error_message), response.code)
    rescue StandardError => e
      Rails.logger.error("WhatCounts newsletter signup exception: #{e.class}: #{e.message}")
      failure(GENERIC_ERROR_MESSAGE)
    end

    def unsubscribe
      return failure(CONFIGURATION_ERROR_MESSAGE) if missing_configuration?

      lookup = lookup_subscribers
      return lookup if !lookup.success?

      if !lookup.subscribed
        return success(ALREADY_UNSUBSCRIBED_MESSAGE, lookup.status_code, false)
      end

      response = HTTParty.get(
        unsubscribe_url,
        timeout: 10
      )

      if response.code.to_i == 200 && response.body.to_s.include?("SUCCESS")
        success(UNSUBSCRIBE_SUCCESS_MESSAGE, response.code, false)
      else
        error_message = extract_error_message(response)
        Rails.logger.error(
          "WhatCounts newsletter unsubscribe failed: status=#{response.code} error=#{error_message.presence || response.body} subscriber_id=#{lookup.subscriber_id.inspect}"
        )
        failure(GENERIC_ERROR_MESSAGE, response.code)
      end
    rescue StandardError => e
      Rails.logger.error("WhatCounts newsletter unsubscribe exception: #{e.class}: #{e.message}")
      failure(GENERIC_ERROR_MESSAGE)
    end

    private

    attr_reader :email, :custom_is_subscriber

    LookupResult = Struct.new(:success, :status_code, :subscribers, :subscribed, :subscriber_id, :message, keyword_init: true) do
      def success?
        success
      end
    end

    def success(message, status_code = nil, subscribed = nil)
      Result.new(success: true, message: message, status_code: status_code, subscribed: subscribed)
    end

    def failure(message, status_code = nil, subscribed = nil)
      Result.new(success: false, message: message, status_code: status_code, subscribed: subscribed)
    end

    def subscribe_url
      http_api_url(
        c: "sub",
        list_id: list_id,
        format: 99,
        data: subscribe_data,
        override_confirmation: 1,
        force_sub: 1
      )
    end

    def find_url
      http_api_url(
        c: "find",
        list_id: list_id,
        email: email
      )
    end

    def unsubscribe_url
      http_api_url(
        c: "unsub",
        list_id: list_id,
        data: "email^#{email}"
      )
    end

    def subscribe_data
      columns = ["email", "custom_pref_monthly_edition", "custom_aus_web_signup"]
      values = [sanitize_http_api_value(email), "1", "1"]
      if !custom_is_subscriber.nil?
        columns << "custom_is_subscriber"
        values << (custom_is_subscriber ? "1" : "0")
      end

      "#{columns.join(",")}^#{values.join(",")}"
    end

    def lookup_subscribers
      response = HTTParty.get(
        find_url,
        timeout: 10
      )

      if response.code.to_i != 200
        error_message = extract_error_message(response)
        Rails.logger.error(
          "WhatCounts newsletter lookup failed: status=#{response.code} error=#{error_message.presence || response.body}"
        )
        return LookupResult.new(
          success: false,
          status_code: response.code,
          subscribers: [],
          subscribed: false,
          subscriber_id: nil,
          message: GENERIC_ERROR_MESSAGE
        )
      end

      body = response.body.to_s
      lookup = parse_http_find_result(body)
      if lookup[:error_message].present?
        Rails.logger.error(
          "WhatCounts newsletter lookup failed: status=#{response.code} error=#{lookup[:error_message]}"
        )
        return LookupResult.new(
          success: false,
          status_code: response.code,
          subscribers: [],
          subscribed: false,
          subscriber_id: nil,
          message: GENERIC_ERROR_MESSAGE
        )
      end

      if !lookup[:matched]
        Rails.logger.info("WhatCounts newsletter lookup returned no match for email=#{email}")
        return not_subscribed_lookup_result(response.code)
      end

      subscriptions_response = HTTParty.get(
        subscriptions_url(lookup[:subscriber_id]),
        headers: rest_headers,
        timeout: 10
      )

      if subscriptions_response.code.to_i != 200
        error_message = extract_error_message(subscriptions_response)
        Rails.logger.error(
          "WhatCounts newsletter subscriptions lookup failed: status=#{subscriptions_response.code} error=#{error_message.presence || subscriptions_response.body} subscriber_id=#{lookup[:subscriber_id].inspect}"
        )
        return LookupResult.new(
          success: false,
          status_code: subscriptions_response.code,
          subscribers: [],
          subscribed: false,
          subscriber_id: lookup[:subscriber_id],
          message: GENERIC_ERROR_MESSAGE
        )
      end

      subscriptions = extract_subscriptions(subscriptions_response.parsed_response)
      subscribed = subscriptions.any? { |subscription| subscription_list_id(subscription).to_s == list_id.to_s }

      Rails.logger.info(
        "WhatCounts newsletter lookup email=#{email} subscriber_id=#{lookup[:subscriber_id].inspect} subscription_list_ids=#{subscriptions.map { |subscription| subscription_list_id(subscription) }.inspect}"
      )

      LookupResult.new(
        success: true,
        status_code: subscriptions_response.code,
        subscribers: subscriptions,
        subscribed: subscribed,
        subscriber_id: lookup[:subscriber_id],
        message: subscribed ? STATUS_SUBSCRIBED_MESSAGE : STATUS_UNSUBSCRIBED_MESSAGE
      )
    end

    def not_subscribed_lookup_result(status_code)
      LookupResult.new(
        success: true,
        status_code: status_code,
        subscribers: [],
        subscribed: false,
        subscriber_id: nil,
        message: STATUS_UNSUBSCRIBED_MESSAGE
      )
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

    def http_api_success?(response)
      response.code.to_i == 200 && response.body.to_s.start_with?("SUCCESS:")
    end

    def parse_http_find_result(body)
      normalized_body = body.to_s.strip
      return { matched: false, subscriber_id: nil, error_message: nil } if normalized_body.blank?

      if normalized_body.downcase.start_with?("failure:")
        return {
          matched: false,
          subscriber_id: nil,
          error_message: no_match_lookup_failure?(normalized_body) ? nil : normalized_body
        }
      end

      lines = normalized_body.split(/\r?\n/).map(&:strip).reject(&:blank?)
      matching_line = lines.find do |line|
        fields = line.split(/\s+/)
        fields[1].to_s.casecmp?(email)
      end
      return { matched: false, subscriber_id: nil, error_message: nil } if matching_line.blank?

      fields = matching_line.split(/\s+/, 3)
      subscriber_id = fields[0].to_i if fields[0].to_s.match?(/\A\d+\z/)

      {
        matched: true,
        subscriber_id: subscriber_id,
        error_message: nil
      }
    end

    def no_match_lookup_failure?(body)
      body.to_s.downcase.include?("no matching record")
    end

    def extract_subscriptions(parsed_response)
      normalized_response =
        case parsed_response
        when String
          JSON.parse(parsed_response)
        else
          parsed_response
        end

      case normalized_response
      when Hash
        subscriptions = normalized_response["subscriptions"] || normalized_response[:subscriptions]
        Array(subscriptions)
      when Array
        normalized_response
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    def subscription_list_id(subscription)
      subscription["listId"] || subscription[:listId] || subscription.dig("dto", "listId") || subscription.dig(:dto, :listId)
    end

    def friendly_error_message(error_message)
      return INVALID_EMAIL_MESSAGE if invalid_email_error?(error_message)

      GENERIC_ERROR_MESSAGE
    end

    def duplicate_subscription?(error_message)
      error_message.to_s.include?(DUPLICATE_SUBSCRIPTION_ERROR)
    end

    def invalid_email_error?(error_message)
      error_message.to_s.downcase.include?("email")
    end

    def sanitize_http_api_value(value)
      value.to_s.gsub(/[,\^]/, " ").strip
    end

    def missing_configuration?
      [base_url, realm_name, api_password, list_id].any?(&:blank?)
    end

    def base_url
      ENV["WHATCOUNTS_BASE_URL"].to_s.sub(%r{/*\z}, "")
    end

    def legacy_api_web_url
      return base_url if base_url.end_with?("/bin/api_web", "/api_web")

      "#{whatcounts_host_url}/bin/api_web"
    end

    def rest_headers
      {
        "Authorization" => "Basic #{basic_auth}",
        "Accept" => ACCEPT_HEADER,
        "Content-Type" => CONTENT_TYPE_HEADER
      }.tap do |request_headers|
        if api_client_name.present? && api_client_auth_code.present?
          request_headers["x-api-key"] = Base64.strict_encode64("#{api_client_name}:#{api_client_auth_code}")
        end
      end
    end

    def subscriptions_url(subscriber_id)
      "#{whatcounts_host_url}/rest/subscribers/#{subscriber_id}/subscriptions"
    end

    def http_api_url(params)
      "#{legacy_api_web_url}?#{URI.encode_www_form(http_api_params.merge(params))}"
    end

    def http_api_params
      {
        api_client: api_client_name.presence,
        client_auth: api_client_auth_code.presence,
        r: realm_name,
        p: api_password
      }.compact
    end

    def whatcounts_host_url
      base_url.sub(%r{/(?:bin/)?api_web\z}, "").sub(%r{/rest\z}, "")
    end

    def basic_auth
      Base64.strict_encode64("#{realm_name}:#{api_password}")
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
