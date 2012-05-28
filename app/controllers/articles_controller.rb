class ArticlesController < ApplicationController

	# Cancan authorisation
  	load_and_authorize_resource

  	def index
  		@issue = Issue.find(params[:issue_id])
  		@article = Issue.find(params[:issue_id])
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

    def show
    	@issue = Issue.find(params[:issue_id])
    	@article = Issue.find(params[:issue_id])
    end

end
