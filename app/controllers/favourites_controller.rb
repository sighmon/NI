class FavouritesController < ApplicationController
  # Cancan authorisation
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    session[:user_return_to] = request.referer
    if not current_user
      redirect_to new_user_session_path, alert: "You need to be logged in to add this article to your favourites."
    else
      redirect_to (session[:user_return_to] or issues_path), alert: exception.message
    end
  end

  def create
    @user = User.find(current_user.id)
    @issue = Issue.find(params[:issue_id])
    @article = Article.find(params[:article_id])
    @favourite = Favourite.create(user_id: @user.id, issue_id: @issue.id, article_id: @article.id)
    @favourite.created_at = DateTime.now

    respond_to do |format|
      if @favourite.save
        format.html { redirect_to issue_article_path(@issue, @article), notice: 'This article has been added to your favourites.' }
        format.json { render json: @favourite, status: :created, location: @favourite }
      else
        format.html { redirect_to issue_article_path(@issue, @article), notice: "Sorry, couldn't favourite this article." }
        format.json { render json: @favourite.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(current_user.id)
    @issue = Issue.find(params[:issue_id])
    @article = Article.find(params[:article_id])
    @favourite = Favourite.find(params[:id])

    respond_to do |format|
      if @favourite.destroy
        format.html { redirect_to issue_article_path(@issue, @article), notice: 'This article has been removed from your favourites.' }
        format.json { head :no_content }
      else
        format.html { redirect_to user_path(@user), notice: "Sorry, couldn't remove this favourite." }
        format.json { render json: @favourite.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def favourite_params
    # params.require(:favourite).permit(:article_id, :created_at, :issue_id, :user_id)
    params.fetch(:favourite, {}).permit(:article_id, :created_at, :issue_id, :user_id)
  end

end
