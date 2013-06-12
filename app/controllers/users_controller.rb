class UsersController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to view your profile."
    end

    def show

    end

    def re_sign_in
      sign_out :user
      redirect_to new_user_session_path
    end
end
