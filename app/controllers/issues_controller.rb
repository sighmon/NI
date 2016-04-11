class IssuesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource :except => [:index]

  newrelic_ignore :only => [:email, :email_non_subscribers, :email_others, :email_renew]
  # newrelic_ignore_enduser :only => [:email, :email_non_subscribers, :email_others, :email_renew]
  # NOTE: if setting up another email, don't forget to add it to ability.rb too :-)

  # :show So that iOS can post, :index so that issues.json jquery works
  skip_before_filter :verify_authenticity_token, :only => [:show, :index]

  # Devise authorisation
  # before_filter :authenticate_user!, :except => [:show, :index]

  # GET /issues
  # GET /issues.json

  def import
    @issue = Issue.find(params[:issue_id])
    @issue.import_articles_from_bricolage(nil)
    redirect_to issue_path(@issue)
  end

  def import_extra
    article_type = params[:article_type]
    @issue = Issue.find(params[:issue_id])
    @issue.import_articles_from_bricolage(article_type)
    redirect_to issue_path(@issue)
  end

  def import_images
    @issue = Issue.find(params[:issue_id])
    @issue.articles.each do |article|
      article.import_media_from_bricolage
    end
    redirect_to issue_path(@issue)
  end

  def import_categories
    @issue = Issue.find(params[:issue_id])
    @issue.articles.each do |article|
      article.import_categories_from_source
    end
    redirect_to issue_path(@issue)
  end

  def index
    # @issues = Issue.all
    # Pagination
    # @issues = Issue.order("release").reverse_order.page(params[:page]).per(2)
    # Search
    # @issues = Issue.search(params)
    # TOFIX: TODO: Search + pagination?
    # @issues = Issue.order("release").reverse_order.page(params[:page]).per(2).search(params)

    @issues = Issue.search(params, current_user.try(:admin?))
    @json_issues = Issue.select {|i| i.published?}.sort_by { |i| i.release }.reverse

    # Set meta tags
    @page_title = "Magazine archive"
    @page_description = "An archive of all the New Internationalist magazines available as digital editions."

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, archive, digital, edition",
                  :canonical => issues_url,
                  :alternate => [
                    {:href => "android-app://#{ENV['GOOGLE_PLAY_APP_PACKAGE_NAME']}/newint/issues"}, 
                    {:href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/issues"},
                    {:href => rss_url(format: :xml), :type => 'application/rss+xml', :title => 'RSS'}
                  ],
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issues_url,
                    :image => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s
                    },
                    :app => {
                      :name => {
                        :iphone => ENV["ITUNES_APP_NAME"],
                        :ipad => ENV["ITUNES_APP_NAME"]
                      },
                      :id => {
                        :iphone => ENV["ITUNES_APP_ID"],
                        :ipad => ENV["ITUNES_APP_ID"]
                      },
                      :url => {
                        :iphone => "newint://issues",
                        :ipad => "newint://issues"
                      }
                    }
                  }

    if not params[:query].blank?
      @json_issues = @issues
    end

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @issues, callback: params[:callback] }
      format.json { render callback: params[:callback], json: Issue.issues_index_to_json(@json_issues) }
    end
  end

  def email
    @issue = Issue.find(params[:issue_id])
    # sections_of_articles_definitions
    
    # Set meta tags
    @page_title = @issue.title
    @page_description = "Read the #{@issue.release.strftime("%B, %Y")} digital edition of the New Internationalist magazine - #{@issue.title}"

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@issue.title}",
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issue_url(@issue),
                    :image => @issue.cover_url(:thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issue.cover_url(:thumb2x).to_s
                    }
                  }
    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def email_non_subscribers
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def email_others
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def email_renew
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def zip
    @issue = Issue.find(params[:issue_id])
    @issue.zip_for_ios
    redirect_to @issue, notice: "Zip created."
  end

  def send_push_notification
    # Send a parse push notification
    @issue = Issue.find(params[:issue_id])
    input_params = params["/issues/#{@issue.id}/send_push_notification"]
    @alert_text = input_params[:alert_text]
    @device_id = input_params[:device_id]

    if not Rails.env.production?
      # If development environment, always push to dev device
      @device_id = ENV["PARSE_DEV_DEVICE_ID"]
    end

    # Scheduled datetime is in UTC(GMT)
    @scheduled_datetime = DateTime.new(input_params["scheduled_datetime(1i)"].to_i, input_params["scheduled_datetime(2i)"].to_i, input_params["scheduled_datetime(3i)"].to_i, input_params["scheduled_datetime(4i)"].to_i, input_params["scheduled_datetime(5i)"].to_i)

    api_endpoint = ENV["PARSE_API_ENDPOINT"]
    api_headers = {
      "X-Parse-Application-Id" => ENV["PARSE_APPLICATION_ID"],
      "X-Parse-REST-API-Key" => ENV["PARSE_REST_API_KEY"],
      "Content-Type" => "application/json"
    }
    api_body = {
      "where" => {
        "objectId" => @device_id #Just push to a single user
        # "deviceType" => "ios" # Now sending to Android too!
      },
      "push_time" => @scheduled_datetime.to_time.iso8601.to_s,
      "data" => {
        "alert" => "#{@alert_text + @issue.push_notification_text}",
        "badge" => "Increment",
        "sound" => "new-issue.caf",
        "name" => @issue.number.to_s,
        "publication" => @issue.release.to_time.iso8601.to_s,
        "railsID" => @issue.id.to_s
      }
    }

    # Remove "objectId" if no @device_id is present
    api_body["where"].reject!{|k,v| v.empty?}
    api_body = api_body.to_json

    # logger.info "PARSE to post to api - body: #{api_body.to_s}"

    begin
      response = HTTParty.post(
        api_endpoint,
        headers: api_headers,
        body: api_body
      )
    rescue => e
      # Uh oh, Parse not available?
      @httparty_error = e
    end
    
    if not @httparty_error and response and response.code == 200
      # Success!
      # body = JSON.parse(response.body)

      # Mark the scheduled to send date, unless a single device push was sent.
      @issue.notification_sent = @scheduled_datetime unless not @device_id.blank?
      
      if @issue.save
        redirect_to @issue, notice: "Push sent!"
      else
        redirect_to @issue, flash: { error: "Couldn't update issue after push successfully sent." }
      end
    else
      # FAIL! server error.
      redirect_to @issue, flash: { error: "Failed to push. Response: #{response.to_s unless !response}, Error: #{@httparty_error unless !@httparty_error}" }
    end
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
    # @issue = Issue.find(params[:id])
    # TOFIX: Sort articles by :position using jquery

    # Load section definitions
    #sections_of_articles_definitions
    #moved to the model

    @categories = @issue.all_articles_categories.sort_by(&:short_display_name)
    
    # Set meta tags
    @page_title = @issue.title
    @page_description = "#{@issue.release.strftime("%B, %Y")} - #{ActionView::Base.full_sanitizer.sanitize(@issue.keynote.try(:teaser))}"

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@issue.title}",
                  :canonical => issue_url(@issue),
                  :alternate => [
                    {:href => "android-app://#{ENV['GOOGLE_PLAY_APP_PACKAGE_NAME']}/newint/issues/#{@issue.id}"}, 
                    {:href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/issues/#{@issue.id}"},
                    {:href => rss_url(format: :xml), :type => 'application/rss+xml', :title => 'RSS'}
                  ],
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issue_url(@issue),
                    :image => @issue.cover_url.to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issue.cover_url.to_s
                    },
                    :app => {
                      :name => {
                        :iphone => ENV["ITUNES_APP_NAME"],
                        :ipad => ENV["ITUNES_APP_NAME"]
                      },
                      :id => {
                        :iphone => ENV["ITUNES_APP_ID"],
                        :ipad => ENV["ITUNES_APP_ID"]
                      },
                      :url => {
                        :iphone => "newint://issues/#{@issue.id}",
                        :ipad => "newint://issues/#{@issue.id}"
                      }
                    }
                  }

    respond_to do |format|
      format.html # show.html.erb
      if request.post?
        if request_has_valid_rails_subscription or request_has_purchased_rails_issue or request_has_valid_itunes_subscription or request_has_valid_google_play_receipt
          zip_url_for_json = @issue.zip.url
          if Rails.env.development?
            zip_url_for_json = "#{request.protocol}#{request.host_with_port}#{@issue.zip.url}"
          end
          format.json { render json: { :id => @issue.id, :name => @issue.number, :publication => @issue.release, :zipURL => zip_url_for_json } }
        else
          format.json { render nothing: true, status: :forbidden }
        end
      else
        format.json { render json: issue_show_to_json(@issue) }
      end
    end
  end

  def issue_show_to_json(issue)
    issue.to_json(
      #not super dry, see format block in #show
      # this is everything you should see about an issue without purchasing/subscribing
      # hoping that the only pay-walled content is :body
      # this isn't used by the app - we get it from the issues.json
      #:only => [:title, :id, :number, :editors_name, :editors_photo, :release, :cover],
      #:methods => [:editors_letter_html],
      :only => [],
      :include => { 
        :articles => Issue.article_information_to_include_in_json_hash,
      } 
    )
  end

  # GET /issues/new
  # GET /issues/new.json
  def new
    # @issue = Issue.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @issue }
    end
  end

  # GET /issues/1/edit
  def edit
    # @issue = Issue.find(params[:id])
    # Use cancan to check for individual authorisation
    # authorize! :update, @issue

    set_meta_tags :title => "Edit this Issue"
  end

  # POST /issues
  # POST /issues.json
  def create
    # @issue = Issue.new(params[:issue])

    respond_to do |format|
      if @issue.save
        format.html { redirect_to @issue, notice: 'Issue was successfully created.' }
        format.json { render json: @issue, status: :created, location: @issue }
      else
        format.html { render action: "new" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /issues/1
  # PUT /issues/1.json
  def update
    # @issue = Issue.find(params[:id])

    respond_to do |format|
      if @issue.update_attributes(issue_params)
        format.html { redirect_to @issue, notice: 'Issue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    # @issue = Issue.find(params[:id])
    # For some reason @issue.destroy doesn't work anymore postgres?
    @issue.destroy
    # @issue.delete

    respond_to do |format|
      format.html { redirect_to issues_url }
      format.json { head :no_content }
    end
  end

  def tweet_issue
    @issue = Issue.find(params[:issue_id])
    twitter_params = {
      :url => issue_url(@issue),
      :text => "I'm reading '#{@issue.title}'",
      :via => "#{ENV["TWITTER_NAME"]}"
      #:related => "#{ENV["TWITTER_NAME"]}"
    }
    redirect_to "https://twitter.com/share?#{twitter_params.to_query}"
  end

  def wall_post_issue
    @issue = Issue.find(params[:issue_id])
    facebook_params = {
      :app_id => ENV["FACEBOOK_APP_ID"],
      :link => issue_url(@issue),
      :picture => @issue.cover_url.to_s,
      :name => @issue.title,
      :caption => ActionController::Base.helpers.strip_tags(@issue.try(:keynote).try(:teaser)),
      :description => "New Internationalist magazine, #{@issue.release.strftime("%B, %Y")}",
      :redirect_uri => issue_url(@issue)
    }
    redirect_to "https://www.facebook.com/dialog/feed?#{facebook_params.to_query}"
  end

  def email_issue
    @issue = Issue.find(params[:issue_id])
    email_params = {
      :body => issue_url(@issue),
      :subject => "#{@issue.title} - New Internationalist Magazine"
    }
    redirect_to "mailto:?#{email_params.to_query}"
  end

  private

  # TOFIX: iTunes receipt validation is also in articles_controller.rb and user.rb
  # Ask Pix how to dry up private methods.

  def request_has_valid_rails_subscription
    if !request.post?
      return false
    end

    if current_user
      rails_expiry = current_user.expiry_date
      logger.info "Rails user: #{current_user.expiry_date}"
    end

    if rails_expiry and (rails_expiry > DateTime.now)
      logger.info "Rails subscription VALID: #{rails_expiry}"
      return true
    elsif rails_expiry and (rails_expiry < DateTime.now)
      logger.info "Rails subscription EXPIRED: #{rails_expiry}"
      return false
    else
      logger.warn "Rails INVALID: This user doesn't have a subscription."
      return false
    end

  end

  def request_has_purchased_rails_issue
    if !request.post?
      return false
    end

    if current_user and current_user.purchases.collect{|p| p.issue_id}.include?(@issue.id)
      logger.info "Rails PURCHASE: This user has purchased issue #{@issue.id}"
      return true
    else
      logger.info "Rails purchase: issue hasn't been purchased."
      return false
    end
  end

  def request_has_valid_itunes_subscription
    if !request.post?
      return false
    elsif request.headers["CONTENT_TYPE"].include?("json")
      return false
    end

    # send the request to itunes connect

    if Rails.env.production?
      itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_PRODUCTION"]
    else
      itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_DEV"]
    end

    uri = URI.parse(itunes_url)
    http = Net::HTTP.new(uri.host, uri.port)

    json = { "receipt-data" => request.raw_post, "password" => ENV["ITUNES_SECRET"] }.to_json
    http.use_ssl = true
    api_response, data = http.post(uri.path,json)

    subscription_receipt_valid = false

    # Do a first check to see if the receipt is valid from iTunes
    if JSON.parse(api_response.body)["status"] != 0
      logger.warn "receipt-data: #{request.raw_post}"
      subscription_receipt_valid = false
    else
      # Check purchased issues from receipts
      purchased_issue_numbers = purchased_issues_from_receipts(api_response.body)

      # Check purchased subscriptions from receipts
      ios_expiry = latest_subscription_expiry_from_recepits(api_response.body)
    end      

    if ios_expiry and (ios_expiry > DateTime.now)
      logger.info "iOS sub valid till: #{ios_expiry}"
      subscription_receipt_valid = true
    end

    # Check to see if those receipts allow the person to read this issue
    if subscription_receipt_valid
      logger.info "iTunes: This user has a valid subscription."
      return true
    elsif purchased_issue_numbers and purchased_issue_numbers.include?(@issue.number.to_s)
      logger.info "iTunes: This user purchased issue: #{@issue.number}"
      return true
    else
      logger.warn "iTunes: This user doesn't have access to download this issue."
      return false
    end
  end

  def purchased_issues_from_receipts(response)
    purchases = JSON.parse(response)['receipt']['in_app']

    issues_purchased = []

    purchases.each do |item|
      if item['product_id'].include?('single')
        issues_purchased << item['product_id'][0..2]
        # TODO: check if purchase already exists and if not, create a new one
      end
    end

    logger.info "iTunes Issues purchased: "
    logger.info issues_purchased

    return issues_purchased
  end

  def latest_subscription_expiry_from_recepits(response)
    purchases = JSON.parse(response)['receipt']['in_app']

    subscriptions = []
    latest_expiry = "0"

    purchases.each do |item|
      if item['product_id'].include?('month')
        if item['expires_date_ms'].nil?
          # The subscription is non-renewing, generate :expires_date_ms for it.
          subscription_duration = item['product_id'][0..1].to_i
          item['expires_date_ms'] = ((Time.at(item['original_purchase_date_ms'].to_i / 1000).to_datetime + subscription_duration.months).to_i * 1000).to_s
          logger.info "iTunes Non-renewing subscription, synthesized date: (#{item['expires_date_ms']})"
        end
        subscriptions << item
        # TODO: check if they already have a subscription in Rails, if not, purchase one
      end
    end

    logger.info "Susbcriptions purchased: "
    logger.info subscriptions

    if not subscriptions.empty?
      latest_expiry = subscriptions.sort_by{ |x| x["expires_date_ms"]}.last["expires_date_ms"]
    end

    sec = (latest_expiry.to_f / 1000).to_s

    latest_sub_date = DateTime.strptime(sec, '%s')

    logger.info "Latest subscription expiry date: "
    logger.info latest_sub_date

    return latest_sub_date
  end

  def request_has_valid_google_play_receipt
    if !request.post?
      return false
    elsif not request.headers["CONTENT_TYPE"].include?("json")
      return false
    end

    require 'google/api_client'
    require 'google/api_client/client_secrets'
    require 'google/api_client/auth/installed_app'
    require 'google/api_client/auth/file_storage'

    # Initialize the Google Play client.
    client = Google::APIClient.new(
      :application_name => ENV["APP_NAME"],
      :application_version => '1.0.0'
    )

    # Get Client Authorization
    # http://stackoverflow.com/questions/25828491/android-verify-iap-subscription-server-side-with-ruby
    # NOTE: To setup permissions to use the API, you need to setup a Service Account in the Developer Console
    # APIs & Auth > Credentials > Create new ClientID > Service Account
    # Then in Google Play > Settings > API Access > Link & then give permission: View financial reports
    # key = Google::APIClient::KeyUtils.load_from_pkcs12(IO.read(Rails.root + "config/google_play.p12"), ENV["GOOGLE_PLAY_P12_SECRET"])
    # Downloaded the .p12 from Google Play, and then openssl it into a .pem
    # Base64 that into an environment variable to keep it out of version control and Heroku happy.
    key = Google::APIClient::KeyUtils.load_from_pem(Base64.decode64(ENV["GOOGLE_PLAY_PEM_BASE64"]), nil)
    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/androidpublisher',
      :issuer => ENV["GOOGLE_PLAY_SERVICE_EMAIL"],
      :signing_key => key,
      :access_type => 'offline'
    )
    client.authorization.fetch_access_token!

    # Discover the API
    publisher = client.discovered_api('androidpublisher', 'v2')

    # logger.info "Android raw_post: #{request.raw_post}"
    if !request.raw_post.empty?
      purchases_json = JSON.parse(request.raw_post)

      has_valid_receipt = false

      # Check purchase with Google Play
      purchases_json.each do |p|
        if p["productId"].include?("single")

          if p["productId"].include?("#{@issue.number}single")
            # Receipt appears to be for this issue, so validate it
            result = client.execute(
              :api_method => publisher.purchases.products.get,
              :parameters => {
                'packageName' => ENV["GOOGLE_PLAY_APP_PACKAGE_NAME"], 
                'productId' => p["productId"], 
                'token' => p["purchaseToken"]
              }
            )

            result_json = JSON.parse(result.body)

            if result_json["purchaseState"] == 0
              logger.info "Google Play: VALID purchase: #{result.body}"
              has_valid_receipt = true
            else
              logger.info "Google Play: INVALID purchase: #{result.body}"
            end
          else
            # Receipt isn't for this issue..
            logger.info "Google Play: INVALID: #{p["productId"]}, but this issue is: #{@issue.number}single."
          end

        elsif p["productId"].include?("month")
          # It's a subscription, validate it
          result = client.execute(
            :api_method => publisher.purchases.subscriptions.get,
            :parameters => {
              'packageName' => ENV["GOOGLE_PLAY_APP_PACKAGE_NAME"], 
              'subscriptionId' => p["productId"], 
              'token' => p["purchaseToken"]
            }
          )

          result_json = JSON.parse(result.body)
          # logger.info "TODO: Google Play: It's a subscription - #{result.body}"

          if result_json["kind"] == "androidpublisher#subscriptionPurchase"
            # It's a subscription purchase, so test its expiryTimeMillis
            google_play_subscription_expiry_date = DateTime.strptime((result_json["expiryTimeMillis"].to_i/1000).to_s, '%s').in_time_zone('Adelaide')
            time_now_in_adelaide = DateTime.now.in_time_zone('Adelaide')
            if google_play_subscription_expiry_date > time_now_in_adelaide
              # Subscription is valid
              logger.info "Google Play Subscription VALID: #{google_play_subscription_expiry_date}"
              has_valid_receipt = true
            else
              # Subscription has expired
              logger.info "Google Play Subscription EXPIRED: #{google_play_subscription_expiry_date}"
            end
          end
        else
          logger.info "Google Play ERROR: No receipt matches NI products."
        end
      end

      if has_valid_receipt
        return true
      else
        return false
      end

    else
      # No post data to send..
      return false
    end
  end

  def issue_params
    params.require(:issue).permit(:number, :release, :title, :trialissue, :cover, :editors_letter, :editors_name, :editors_photo, :published, :email_text, :zip, :digital_exclusive)
  end

end
