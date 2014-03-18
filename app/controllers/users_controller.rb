class UsersController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to view your profile."
    end

    skip_before_filter :verify_authenticity_token, :only => [:show]

    def show
        respond_to do |format|
            format.html
            format.json {
                # Ignore user request and just use current_user
                @user = current_user
                render json: user_show_to_json(@user) 
            }
        end
    end

    def user_show_to_json(user)
        # TODO: Fix this deprecation warning
        user["expiry_date"] = user.expiry_date_including_ios(request)
        user.to_json(
            :only => [:username, :id, :expiry_date]
        )
    end

    def re_sign_in
      sign_out :user
      redirect_to new_user_session_path
    end
end
