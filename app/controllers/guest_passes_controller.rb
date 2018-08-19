class GuestPassesController < ApplicationController
  
  # Cancan authorisation
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    session[:user_return_to] = request.referer
    if not current_user
      redirect_to new_user_session_path, :alert => "You need to be logged in to make a guest pass."
    else
      redirect_to (session[:user_return_to] or issues_path), :alert => exception.message
    end
  end

  def create
    @user = User.find(current_user.id)
    @issue = Issue.find(params[:issue_id])
    @article = Article.find(params[:article_id])
    @guest_pass = GuestPass.create(:user_id => @user.id, :article_id => @article.id)
    #@guest_pass.created_at = DateTime.now

    respond_to do |format|
      if @guest_pass.save
        format.html { redirect_to issue_article_path(@issue, @article), notice: "A guest pass for this article has been created for you to share with friends. Click on your username to see all the articles you're sharing." }
        format.json { render json: @guest_pass, status: :created, location: @guest_pass }
      else
        format.html { redirect_to issue_article_path(@issue, @article), notice: "Sorry, couldn't share this article." }
        format.json { render json: @guest_pass.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(current_user.id)
    @issue = Issue.find(params[:issue_id])
    @article = Article.find(params[:article_id])
    @guest_pass = GuestPass.find(params[:id])

    respond_to do |format|
      if @guest_pass.destroy
        format.html { redirect_to issue_article_path(@issue, @article), notice: 'This guest pass has been destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to user_path(@user), notice: "Sorry, couldn't destroy this guest_pass." }
        format.json { render json: @guest_pass.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def guest_pass_params
    # params.require(:guest_pass).permit(:article_id, :user_id)
    params.fetch(:guest_pass, {}).permit(:article_id, :user_id)
  end

end
