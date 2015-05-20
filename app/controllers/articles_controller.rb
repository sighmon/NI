class ArticlesController < ApplicationController
    require 'net/http'

    include ArticlesHelper
   
    skip_before_filter :verify_authenticity_token, :only => [:body, :body_android, :ios_share]

    # Cancan authorisation
    # Except :body to allow for iTunes authentication.
    load_and_authorize_resource :except => [:body, :body_android, :ios_share]
    # load_and_authorize_resource

    def strip_tags(string)
        ActionController::Base.helpers.strip_tags(string)
    end

    rescue_from CanCan::AccessDenied do |exception|
        if @article
            redirect_to new_issue_purchase_path(@article.issue), :alert => "You need to purchase this issue or subscribe to read this article."
        else
            redirect_to root_path
        end
    end

    def search
        @articles = Article.search(params, current_user.try(:admin?))
        # if params[:query].present?
        #     @articles = Article.search(params[:query], load: true, :page => params[:page], :per_page => Settings.article_pagination)
        # else
        #     @articles = Article.order("publication").reverse_order.page(params[:page]).per(Settings.article_pagination)
        # end
        # @articles = Article.search(params)
        # @articles = Article.all

        # Set meta tags
        set_meta_tags :title => "Search for an article",
                      :description => "Find an article by keyword from the New Internationalist magazine digital archive.",
                      :keywords => "new, internationalist, magazine, digital, edition, search",
                      :canonical => search_url,
                      :open_graph => {
                        :title => "Search for an article",
                        :description => "Find an article by keyword from the New Internationalist magazine digital archive.",
                        #:type  => :magazine,
                        :url   => search_url,
                        :site_name => "New Internationalist Magazine Digital Edition"
                      }
        respond_to do |format|
          format.html # show.html.erb
          
          format.json { render json: @articles.to_json(
            # Don't show :body here
            :only => [:title, :teaser, :keynote, :featured_image, :featured_image_caption, :id],
                :include => {
                  :images => {},
                  :categories => { :only => [:name, :colour, :id] }
                }
          ) }
        end
    end

    def popular
        @guest_passes = GuestPass.all(:order => "use_count").reverse.first(10)

        # Set meta tags
        set_meta_tags :title => "Poplar New Internationalist articles",
                      :description => "Articles from New Internationalist magazine that our readers have found most popular.",
                      :keywords => "new, internationalist, magazine, digital, edition, popular, readers, ordered",
                      :canonical => popular_url,
                      :open_graph => {
                        :title => "Poplar New Internationalist articles",
                        :description => "Articles from New Internationalist magazine that our readers have found most popular.",
                        :url   => popular_url,
                        :image => @guest_passes.first.article.first_image.try(:data_url).to_s,
                        :site_name => "New Internationalist Magazine Digital Edition"
                      },
                      :twitter => {
                        :card => "summary",
                        :site => "@ni_australia",
                        :creator => "@ni_australia",
                        :title => @page_title_home,
                        :description => @page_description,
                        :image => {
                          :src => @guest_passes.first.article.first_image.try(:data_url).to_s
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
                            :iphone => "newint://",
                            :ipad => "newint://"
                          }
                        }
                      }
        respond_to do |format|
          format.html # show.html.erb
          
          format.json { render json: @guest_passes.to_json(
            :include => {
              # Don't show article :body here
              :article => { :only => [:title, :teaser, :keynote, :featured_image, :featured_image_caption, :id, :issue_id] }
            }
          ) }
        end
    end

    def import
        @article = Article.find(params[:article_id])
        @article.issue.import_stories_from_bricolage([@article.story_id])
        redirect_to issue_article_path(@article.issue,@article)
    end

    def import_images
        @article = Article.find(params[:article_id])
        @article.import_media_from_bricolage(force: true)
        redirect_to issue_article_path(@article.issue,@article)
    end

    def index
	@issue = Issue.find(params[:issue_id])
	@article = Article.find(:all)
	# @article = Article.order("created_at").page(params[:page]).per(2).search(params)
        respond_to do |format|
	        format.html
        end
    end

    def new
	@issue = Issue.find(params[:issue_id])
	@article = @issue.articles.build
    end

    def create
        @issue = Issue.find(params[:issue_id])

        # HACK: assign_nested_attributes_for chokes accepting categories_attributes for a yet-to-be-created article
        saved_article_params = params[:article]
        extracted_categories_attributes = params[:article].try(:extract!,:categories_attributes)
        @article = @issue.articles.create(params[:article])
        # HACK: strip out id's so that categories_attributes= pre-emptively associates these categories with the article before
        # handing it to assign_nested_attributes_for
        extracted_categories_attributes.try(:fetch,:categories_attributes).try(:values).try(:each) do |v|
         v.delete(:id)
         v.delete("id")  
        end 
        # Added this check to be able to create an article without a category
        if not extracted_categories_attributes.try(:fetch,:categories_attributes).nil?
            @article.update_attributes(extracted_categories_attributes)
        end
        
        respond_to do |format|
            if @article.save
                format.html { redirect_to issue_path(@issue), notice: 'Article was successfully created.' }
                format.json { render json: @article, status: :created, location: @article }
            else
                format.html { render action: "new", notice: "Uh oh, couldn't create your article, sorry!" }
                format.json { render json: @article.errors, status: :unprocessable_entity }
            end
        end
    end

    def update

    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])

        if params[:article][:body] == source_to_body(@article)
          params[:article][:body] = ""
        end

    	respond_to do |format|
	      if @article.update_attributes(params[:article])
	        format.html { redirect_to issue_article_path, notice: 'Article was successfully updated.' }
	        format.json { head :no_content }
	      else
	        format.html { render action: "edit" }
	        format.json { render json: @article.errors, status: :unprocessable_entity }
	      end
	    end
    end

    def destroy
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])
    	@article.destroy

    	respond_to do |format|
	      format.html { redirect_to issue_path(@issue) }
	      format.json { head :no_content }
	    end
	end

    def show
    	#@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])
        @issue = Issue.find(@article.issue_id)
        #@article.is_valid_guest_pass(params[:utm_source])
        @newimage = Image.new
        @letters = @article.categories.select{|c| c.name.include?("/letters/")}
        # Push the single top image to the right for these categories
        @image_top_right = @article.categories.select{|c| 
            c.name.include?("/letters-from/") or 
            c.name.include?("/sections/agenda/") or
            c.name.include?("/image-top-right/") or 
            c.name.include?("/columns/media/")
        }
        # Display the :sixhundred version for these cartoons
        @cartoon = @article.categories.select{|c| 
            c.name.include?("/columns/polyp/") or 
            c.name.include?("/columns/bbw/") or 
            c.name.include?("/blog/cantankerousfrank/") or 
            c.name.include?("/columns/only-planet/") or
            c.name.include?("/columns/scratchy-lines/") or
            c.name.include?("/columns/open-window/") or
            c.name.include?("/columns/cartoon/") or
            c.name.include?("/graphic/")
        }
        # Make southern exposure images large
        @exposure = @article.categories.select{|c| 
            c.name.include?("/columns/exposure/")
        }
        if not @cartoon.empty?
            @image_url_string = :sixhundred
            @image_css_string = " article-image-cartoon no-shadow"
        elsif not @exposure.empty?
            @image_url_string = :sixhundred
            @image_css_string = " article-image-cartoon"
        elsif not @image_top_right.empty?
            @image_url_string = :threehundred
            @image_css_string = " article-image-top-right article-image"
        else
            @image_url_string = :threehundred
            @image_css_string = ""
        end
        #@images = @article.images.all
        # @article.source_to_body(:debug => current_user.try(:admin?))

        article_category_themes = @article.categories.each.select{|c| c.name.include?("/themes/")}
        # logger.info article_category_themes
        @related_articles = []
        article_category_themes.each do |category| 
            @related_articles += category.articles
        end
        @related_articles -= [@article]
        @related_articles = @related_articles.uniq.sort_by(&:publication).reverse

        first_image_for_meta_data = @article.first_image.try(:data).to_s

        # Set meta tags
        set_meta_tags :title => @article.title,
                      :description => strip_tags(@article.teaser),
                      :keywords => "new, internationalist, magazine, digital, edition, #{@article.title}",
                      :canonical => issue_article_url(@issue, @article),
                      :open_graph => {
                        :title => @article.title,
                        :description => strip_tags(@article.teaser),
                        #:type  => :magazine,
                        :url   => issue_article_url(@issue, @article),
                        :image => first_image_for_meta_data,
                        :site_name => "New Internationalist Magazine Digital Edition"
                      },
                      :twitter => {
                        :card => "summary",
                        :site => "@ni_australia",
                        :creator => "@ni_australia",
                        :title => @article.title,
                        :description => strip_tags(@article.teaser),
                        :image => {
                          :src => first_image_for_meta_data
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
                            :iphone => "newint://issues/#{@article.issue.id}/articles/#{@article.id}",
                            :ipad => "newint://issues/#{@article.issue.id}/articles/#{@article.id}"
                          }
                        }
                      }
    	respond_to do |format|
    	  format.html # show.html.erb
    	end
    end

    def body
      @article = Article.find(params[:article_id])
      # logger.info "article is #{@article}"
      # logger.info "session_id is #{request.session_options[:id]}"
      # logger.info "session is #{session}"
      # logger.info "current_user is #{current_user}"

      if can? :read, @article or request_has_valid_itunes_receipt
        render layout: false
      else
        render nothing: true, status: :forbidden
      end
  
    end

    def body_android
      @article = Article.find(params[:article_id])

      # logger.info "REQUEST: #{request.raw_post}"

      if can? :read, @article or request_has_valid_google_play_receipt
        # Render the body template so we don't repeat code
        render :template => 'articles/body', layout: false
      else
        render nothing: true, status: :forbidden
      end

    end

    def edit
        
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])
        # Moved to _form.html.erb
        # if @article.body.blank?
        #     @article.body = source_to_body(@article, :debug => current_user.try(:admin?))
        # end
    end

    def generate_from_source
      @article = Article.find(params[:article_id])
      @issue = @article.issue
      
      respond_to do |format|
        format.js {}
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

        logger.info "Issues purchased: "
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
                    logger.info "Non-renewing subscription, synthesized date: (#{item['expires_date_ms']})"
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

    def tweet
        @user = User.find(current_user)
        @article = Article.find(params[:article_id])
        @guest_pass = GuestPass.find_or_create_by_user_id_and_article_id(:user_id => @user.id, :article_id => @article.id)
        twitter_params = {
            :url => view_context.generate_guest_pass_link_string(@guest_pass),
            :text => params[:text],
            :via => "ni_australia"
            #:related => "ni_australia"
        }
        redirect_to "https://twitter.com/share?#{twitter_params.to_query}"
    end

    def wall_post
        @user = User.find(current_user)
        @article = Article.find(params[:article_id])
        @guest_pass = GuestPass.find_or_create_by_user_id_and_article_id(:user_id => @user.id, :article_id => @article.id)
        if not @article.featured_image.blank?
            preview_picture = @article.featured_image_url(:fullwidth).to_s
        else
            preview_picture = @article.try(:images).try(:first).try(:data).to_s
        end
        facebook_params = {
            :app_id => 194389730710694,
            :link => view_context.generate_guest_pass_link_string(@guest_pass),
            :picture => preview_picture, #request.protocol + request.host_with_port + preview_picture,
            :name => @article.title,
            :caption => @article.teaser,
            :description => params[:text],
            :redirect_uri => view_context.generate_guest_pass_link_string(@guest_pass)
            #:redirect_uri => "http://digital.newint.com.au"
        }
        redirect_to "https://www.facebook.com/dialog/feed?#{facebook_params.to_query}"
    end

    def email_article
        @user = User.find(current_user)
        @article = Article.find(params[:article_id])
        @guest_pass = GuestPass.find_or_create_by_user_id_and_article_id(:user_id => @user.id, :article_id => @article.id)
        email_params = {
            :body => view_context.generate_guest_pass_link_string(@guest_pass),
            :subject => "#{@article.title} - New Internationalist Magazine"
        }
        redirect_to "mailto:?#{email_params.to_query}"
    end

    def ios_share
        @article = Article.find(params[:article_id])

        if can? :read, @article or request_has_valid_itunes_receipt
            @user = User.find(current_user)
            @guest_pass = GuestPass.find_or_create_by_user_id_and_article_id(:user_id => @user.id, :article_id => @article.id)

            respond_to do |format|
              format.json { render json: @guest_pass }
            end
        else
            render nothing: true, status: :forbidden
        end
    end

    def send_push_notification
        # Send a parse push notification
        @issue = Issue.find(params[:issue_id])
        @article = Article.find(params[:article_id])
        input_params = params["/issues/#{@issue.id}/articles/#{@article.id}/send_push_notification"]
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
            "objectId" => @device_id, #Just push to a single user
            "deviceType" => "ios"
          },
          "push_time" => @scheduled_datetime.to_time.iso8601.to_s,
          "data" => {
            "alert" => "#{@alert_text}",
            "badge" => "Increment",
            "sound" => "new-issue.caf",
            "articleID" => @article.id.to_s,
            "issueID" => @issue.id.to_s
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
          @article.notification_sent = @scheduled_datetime unless not @device_id.blank?
          
          if @article.save
            redirect_to issue_article_path(@issue, @article), notice: "Push sent!"
          else
            redirect_to issue_article_path(@issue, @article), flash: { error: "Couldn't update article after push successfully sent." }
          end
        else
          # FAIL! server error.
          redirect_to issue_article_path(@issue, @article), flash: { error: "Failed to push. Response: #{response.to_s unless !response}, Error: #{@httparty_error unless !@httparty_error}" }
        end
    end

    private

    def request_has_valid_itunes_receipt
      if !request.post?
        return false
      end

      # send the request to itunes connect

      itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_PRODUCTION"]
      uri = URI.parse(itunes_url)
      json = { "receipt-data" => request.raw_post, "password" => ENV["ITUNES_SECRET"] }.to_json

      api_response, data = send_receipt_to_itunes(uri,json)

      if JSON.parse(api_response.body)["status"] != 0
        logger.warn "receipt-data: #{request.raw_post}"
        return false
      end

      # Check purchased issues from receipts
      purchased_issue_numbers = purchased_issues_from_receipts(api_response.body)

      # Check purchased subscriptions from receipts
      subscription_receipt_valid = false

      if latest_subscription_expiry_from_recepits(api_response.body) > DateTime.now
        subscription_receipt_valid = true
      end

      # Check to see if those receipts allow the person to read this article
      if subscription_receipt_valid
        logger.info "This receipt has a valid subscription."
      elsif purchased_issue_numbers.include?(@article.issue.number.to_s)
        logger.info "This receipt includes issue: #{@article.issue.number}"
      else
        logger.warn "This receipt doesn't include access to this article."
        return false
      end

      logger.info "post itunes"
      return true
    end

    def send_receipt_to_itunes(uri,json)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      api_response, data = http.post(uri.path,json)

      # Do a first check to see if the receipt is valid from iTunes
      itunes_response = JSON.parse(api_response.body)["status"]
      logger.info "iTunes response: #{itunes_response}"
      if itunes_response == 21007
        # It's a sandbox receipt, try again with DEV itunes URL
        logger.info "Receipt is a sandbox receipt, trying again..."
        itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_DEV"]
        uri = URI.parse(itunes_url)
        send_receipt_to_itunes(uri,json)
      else
        return api_response, data
      end
      
    end

    def request_has_valid_google_play_receipt
      if !request.post?
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

        # Check purchase with Google Play
        purchases_json.each do |p|
          if p["productId"].include?("single")

            if not p["productId"].include?("#{@article.issue.number}single")
              logger.info "Google Play receipt: #{p["productId"]}, but this issue is: #{@article.issue.number}single."
              return false
            end

            # Make request
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
              logger.info "Google Play: Purchase valid. #{result.body}"
              return true
            else
              logger.info "Google Play: INVALID purchase: #{result.body}"
              return false
            end

          elsif p["productId"].include?("month")
            # TODO: It's a subscription, finish this...
            return false
          else
            logger.info "Google Play ERROR: No receipt matches NI products."
            return false
          end
        end
      else
        # No post data to send..
        return false
      end
    end

end
