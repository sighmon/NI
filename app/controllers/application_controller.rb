class ApplicationController < ActionController::Base
  protect_from_forgery
  # Send the access denied pages to root with a nice message
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to issues_path, :alert => exception.message
  end

  # Save this page location to session
  after_filter :store_location

  private

  def current_ability
    @current_ability ||= Ability.new(current_user, params[:utm_source])
  end

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

end
