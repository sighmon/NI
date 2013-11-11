class ArticlesController < ApplicationController
    require 'net/http'

    include ArticlesHelper
    
    # Cancan authorisation
    # Except :body to allow for iTunes authentication.
    load_and_authorize_resource :except => [:body]
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
                        :image => @article.try(:images).try(:first).try(:data).to_s,
                        :site_name => "New Internationalist Magazine Digital Edition"
                      },
                      :twitter => {
                      :card => "summary",
                      :site => "@ni_australia",
                      :creator => "@ni_australia",
                      :title => @article.title,
                      :description => strip_tags(@article.teaser),
                      :image => {
                        :src => @article.try(:images).try(:first).try(:data).to_s
                      }
                  }
	respond_to do |format|
	  format.html # show.html.erb
	end
    end

    def body
        @article = Article.find(params[:article_id])
        logger.info "article is #{@article}"
        logger.info "session is #{session}"
        begin

          if request.post?
            # send the request to itunes connect

            uri = URI.parse("https://sandbox.itunes.apple.com/verifyReceipt")
            http = Net::HTTP.new(uri.host, uri.port)

            json = { "receipt-data" => request.raw_post, "password" => ENV["ITUNES_SECRET"] }.to_json
            http.use_ssl = true
            api_response, data = http.post(uri.path,json)

            # Do a first check to see if the receipt is valid from iTunes
            if JSON.parse(api_response.body)["status"] != 0
                logger.warn "receipt-data: #{request.raw_post}"
                raise CanCan::AccessDenied
            else
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
                    raise CanCan::AccessDenied
                end
            end

          else
            logger.info "authorize.. #{current_user}"
            authorize! :read, @article unless Rails.env.development?
          end
          render layout:false
        rescue CanCan::AccessDenied
          logger.info "cancan access denied"
          render :nothing => true, :status => :forbidden
        end
        # logger.info "after rescue"
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

end
