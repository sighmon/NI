# Source: https://gist.github.com/jkotchoff/e60fdf048ec443272045
# This class shows uses version 0.28.7 of the ruby google-api-client gem circa April 2019
# to query the Google Play subscription API.
#
# If using an older version of the google-api-client gem (ie. version 0.8.x), instead refer to:
# https://gist.github.com/jkotchoff/e60fdf048ec443272045/e3e2c867633900d9d6f53de2de13aa0a0a16bb03
#
# Sample usage:
#
#   package_name = 'com.stocklight.stocklightapp'
#   product_id = 'com.stocklight.stocklight.standardsubscription'
#   purchase_token = 'kmigoi....4YuSQtU8U'
#   subscription = GooglePlaySubscriptionVerification.new(package_name, product_id, purchase_token)
#
#   => #<Google::Apis::AndroidpublisherV2::SubscriptionPurchase:0x007fbcb3b89698 @auto_renewing=false,
#         @cancel_reason=0, @country_code="AU", @developer_payload="", @expiry_time_millis="1468673994725",
#         @kind="androidpublisher#subscriptionPurchase", @price_amount_micros="9490000", @price_currency_code="AUD",
#         @start_time_millis="1458133289294">
#
#   subscription_cancelled = subscription.cancel_reason.present?
#
# https://developers.google.com/android-publisher/api-ref/purchases/subscriptions
module Services
  class GooglePlayVerification
    require 'google/apis/androidpublisher_v3'
    require 'googleauth'
    require 'googleauth/stores/file_token_store'

    # These credentials come from creating an OAuth Web Application client ID
    # in the Google developer console
    #
    # refer: https://www.youtube.com/watch?v=hfWe1gPCnzc
    #
    # ie.
    # > visit http://console.developers.google.com
    # > API Manager
    # > Credentials
    # > Create Credentials (OAuth client ID)
    # > Application type: Web Application
    # > Authorised redirect URIs: https://developers.google.com/oauthplayground
    # * the resultant client ID / client secret goes in the following GOOGLE_KEY / GOOGLE_SECRET variables
    # > visit: https://developers.google.com/oauthplayground/
    # > Click the settings icon to show the OAuth 2.0 configuration
    # > Tick 'Use your own OAuth credentials'
    # > Enter the OAuth Client ID and OAuth Client secret that you have just created
    # > Check the entry for 'Google Play Developer API v2' in the scopes field and click 'Authorize APIs'
    # > Click 'Allow'
    # > Click 'Exchange authorization code for tokens'
    # * the resultant Refresh token and Access token go in the following REFRESH_TOKEN / ACCESS_TOKEN variables
    GOOGLE_KEY    = ENV['GOOGLE_PLAY_GOOGLE_KEY']
    GOOGLE_SECRET = ENV['GOOGLE_PLAY_GOOGLE_SECRET']
    ACCESS_TOKEN  = ENV['GOOGLE_PLAY_ACCESS_TOKEN']
    REFRESH_TOKEN = ENV['GOOGLE_PLAY_REFRESH_TOKEN']

    Androidpublisher = Google::Apis::AndroidpublisherV3

    # @param package_name - refers to the Google Play package name for the app
    # eg. 'com.stocklight.stocklightapp'
    #
    # @param product_id - refers to the id of the subscription type being checked
    # eg. 'com.stocklight.stocklight.standardsubscription'
    #
    # @param purchase_token - the purchase token receipt
    # eg. 'kmigoi....4YuSQtU8U'
    def initialize(package_name, product_id, purchase_token)
      @package_name = package_name
      @product_id = product_id
      @purchase_token = purchase_token
    end

    # Throws Google::Apis::ClientError if an invalid parameter is provided
    def verify_subscription
      android_publisher.get_purchase_subscription @package_name, @product_id, @purchase_token
    end

    def verify_product
      android_publisher.get_purchase_product @package_name, @product_id, @purchase_token
    end

    private

    def android_publisher
      android_publisher = Androidpublisher::AndroidPublisherService.new.tap do |publisher|
        publisher.authorization = client
        publisher.authorization.fetch_access_token!
      end
    end

    def client(scopes = [Androidpublisher::AUTH_ANDROIDPUBLISHER])
      Signet::OAuth2::Client.new(
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        client_id: GOOGLE_KEY,
        client_secret: GOOGLE_SECRET,
        access_token: ACCESS_TOKEN,
        refresh_token: REFRESH_TOKEN,
        scope: scopes,
      )
    end

  end
end
