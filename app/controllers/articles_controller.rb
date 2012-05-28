class ArticlesController < ApplicationController

  	def index
  		@articles = Article.all
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
    	@article = Article.find(params[:id])
    end

end
