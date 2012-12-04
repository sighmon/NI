class FavouritesController < ApplicationController
	# Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to do that."
    end

    def new
    	# TODO: Check this works!!
    	@user = User.find(current_user)
    	@issue = Issue.find(params[:issue_id])
    	@article = Article.find(params[:article_id])
        @favourite = @user.favourites.build(params[:article])
        session[:issue_id_being_favourited] = @issue.id
        session[:article_id_being_favourited] = @article.id
    end

    def edit

    end

    def create
        @user = User.find(current_user)
        @issue = Issue.find(session[:issue_id_being_favourited])
        @article = Article.find(session[:article_id_being_favourited])
        @favourite = Favourite.create(:user_id => @user.id, :issue_id => @issue.id, :article_id => @article.id)
        @favourite.created_at = DateTime.now

        respond_to do |format|
        	if @favourite.save
        		format.html { redirect_to issue_article_path(@issue, @article), notice: 'This article was added to your favourites.' }
                format.json { render json: @favourite, status: :created, location: @favourite }
            else
                format.html { redirect_to issue_article_path(@issue, @article), notice: "Sorry, couldn't favourite this article." }
                format.json { render json: @favourite.errors, status: :unprocessable_entity }
            end
    end

    def update

    end

end
