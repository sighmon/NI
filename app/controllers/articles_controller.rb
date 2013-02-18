class ArticlesController < ApplicationController
    include ArticlesHelper
	# Cancan authorisation
  	load_and_authorize_resource

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
                      :open_graph => {
                        :title => "Search for an article",
                        :description => "Find an article by keyword from the New Internationalist magazine digital archive.",
                        #:type  => :magazine,
                        :url   => search_url,
                        :site_name => "New Internationalist Magazine Digital Edition"
                      }
    end

    def import_images
        @issue = Issue.find(params[:issue_id])
        @article = Article.find(params[:article_id])
        @article.import_media_from_bricolage(force: true)
        redirect_to issue_article_path(@issue,@article)
    end

  	def index
  		@issue = Issue.find(params[:issue_id])
  		@article = Article.find(:all)
        # @article = Article.order("created_at").page(params[:page]).per(2).search(params)
  	end

  	def new
        @issue = Issue.find(params[:issue_id])
        @article = @issue.articles.build
    end

    def create
        @issue = Issue.find(params[:issue_id])
        @article = @issue.articles.create(params[:article])
        redirect_to issue_path(@issue)
    end

    def update
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])

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
        @article.is_valid_guest_pass(params[:utm_source])
        @newimage = Image.new
        #@images = @article.images.all
        # @article.source_to_body(:debug => current_user.try(:admin?))

        # Set meta tags
        set_meta_tags :title => @article.title,
                      :description => @article.teaser,
                      :keywords => "new, internationalist, magazine, digital, edition, #{@article.title}",
                      :open_graph => {
                        :title => @article.title,
                        :description => strip_tags(@article.teaser),
                        #:type  => :magazine,
                        :url   => issue_article_url(@issue, @article),
                        :image => @article.try(:images).try(:first).try(:data).to_s,
                        :site_name => "New Internationalist Magazine Digital Edition"
                      }
    end

    def edit
        
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])
        # Moved to _form.html.erb
        # if @article.body.blank?
        #     @article.body = source_to_body(@article, :debug => current_user.try(:admin?))
        # end
    end

end
