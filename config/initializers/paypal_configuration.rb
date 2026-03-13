module PaypalConfiguration
  class ConfigurationError < StandardError; end

  module_function

  def sandbox?
    return @sandbox if defined?(@sandbox)

    default_value = Rails.env.production? ? "false" : "true"
    @sandbox = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PAYPAL_SANDBOX", default_value))
  end

  def client_id(sandbox: sandbox?)
    credentials(sandbox: sandbox).fetch(:client_id)
  end

  def secret(sandbox: sandbox?)
    credentials(sandbox: sandbox).fetch(:secret)
  end

  def webhook_id(sandbox: sandbox?)
    prefix = sandbox ? "PAYPAL_SANDBOX" : "PAYPAL"
    ENV["#{prefix}_WEBHOOK_ID"].presence
  end

  def base_url(sandbox: sandbox?)
    sandbox ? "https://api-m.sandbox.paypal.com" : "https://api-m.paypal.com"
  end

  def javascript_sdk_src(sandbox: sandbox?, currency: "AUD", intent: nil, vault: false, components: "buttons")
    params = {
      "client-id" => client_id(sandbox: sandbox),
      components: components,
      currency: currency
    }
    params[:intent] = intent if intent.present?
    params[:vault] = "true" if vault

    "https://www.paypal.com/sdk/js?#{params.to_query}"
  end

  def credentials(sandbox: sandbox?)
    prefix = sandbox ? "PAYPAL_SANDBOX" : "PAYPAL"
    client_id = ENV["#{prefix}_CLIENT_ID"].presence
    secret = first_present(
      "#{prefix}_SECRET_KEY",
      "#{prefix}_CLIENT_SECRET",
      "#{prefix}_SECRET"
    )

    if client_id.blank? || secret.blank?
      raise ConfigurationError, "#{prefix}_CLIENT_ID and #{prefix}_SECRET_KEY are required for the PayPal Orders/Subscriptions API."
    end

    {
      client_id: client_id,
      secret: secret
    }
  end

  def first_present(*keys)
    keys.lazy.map { |key| ENV[key].presence }.find(&:present?)
  end
  private_class_method :first_present
end
