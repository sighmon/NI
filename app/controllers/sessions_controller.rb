 
class SessionsController < Devise::SessionsController

  # this is to allow the ios app to log in (and get the csrf token) even if it is already logged in
  skip_before_filter :require_no_authentication, only: [:create]
  # this stops the warning about no csrf token on /users/sign_in
  skip_before_filter :verify_authenticity_token, only: [:create]

  before_filter :set_csrf_token_header, only: [:create]

  private

  def set_csrf_token_header 
    if request.format == "application/json"
      response.headers["X-CSRF-Token"] = form_authenticity_token
    end
  end

end
