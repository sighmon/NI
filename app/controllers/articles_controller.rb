class ArticlesController < ApplicationController
    include ArticlesHelper
	# Cancan authorisation
  	load_and_authorize_resource :except => [:body]

    def strip_tags(string)
        ActionController::Base.helpers.strip_tags(string)
    end

    rescue_from CanCan::AccessDenied do |exception|
        redirect_to new_issue_purchase_path(@article.issue), :alert => "You need to purchase this issue or subscribe to read this article."
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
        # UNCOMMENT BEFORE PUSHING TO PRODUCTION
        begin
          authorize! :read, @article unless Rails.env.development?
          render layout:false
        rescue CanCan::AccessDenied
          render :nothing => true, :status => :forbidden
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
