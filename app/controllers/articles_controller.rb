class ArticlesController < ApplicationController

	# Cancan authorisation
  	load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        redirect_to new_issue_purchase_path(@article.issue), :alert => "You need to purchase this issue or subscribe to read this article."
    end

    def search
        if params[:query].present?
            @articles = Article.search(params[:query], load: true)
        else
            @articles = Article.all
        end
        # @articles = Article.search(params)
        # @articles = Article.all
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
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])
    end

    def edit
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:id])
    end

end
