 
class SessionsController < Devise::SessionsController

  # this is to allow the ios app to log in (and get the csrf token) even if it is already logged in
  skip_before_action :require_no_authentication, only: [:create]
  # this stops the warning about no csrf token on /users/sign_in
  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :set_csrf_token_header, only: [:create]

  def create
    # Login attempts now try the database strategy, then the remote UK authentication strategy.
    warden.config[:default_strategies][:user].push(warden.config[:default_strategies][:user].shift)
    self.resource = warden.authenticate!(auth_options)
    super
  end

  def new_uk
    # Custom sign-in path /uk_login for UK subscribers
  end

  def after_sign_in_path_for(resource)
    # After successfully logging in, redirect UK users here
    # root_path
    sign_in_url = new_user_session_url
    if request.referer == sign_in_url
      super
    elsif request.referer == uk_login_url
      root_path
    else
      stored_location_for(resource) || request.referer || root_path
    end
  end

  def users_url
    # Failed iOS & Android login attempts hit this on fail.
    # TODO: Work out why that is. But for now..
    logger.info "iOS/Android login incorrect."
    respond_with(nil, status: 401, location: nil)
  end

  private

  def set_csrf_token_header 
    if request.format == "application/json"
      response.headers["X-CSRF-Token"] = form_authenticity_token
    end
  end

end
