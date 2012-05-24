class ApplicationController < ActionController::Base
  protect_from_forgery
  # Send the access denied pages to root with a nice message
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to issues_path, :alert => exception.message
  end
end
