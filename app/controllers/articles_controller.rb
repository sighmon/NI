class ArticlesController < ApplicationController

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
    	@article = Article.find(params[:issue_id])
    end

end
