class UsersController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to view your profile."
    end

    skip_before_filter :verify_authenticity_token, :only => [:show]

    def show

        if @user.institution? or params[:user_type] == "institution"
            @template = "user_mailer/make_institutional_confirmation"
        else
            @template = "user_mailer/user_signup_confirmation"
        end

        respond_to do |format|
            format.html
            format.json {
                # Ignore user request and just use current_user
                @user = current_user
                render json: user_with_expiry_and_purchases(@user)
            }
            format.mjml {
                @greeting = 'Hi'
                if current_user and current_user.admin?
                    @user = User.find(params[:id])
                else
                    @user = current_user
                end
                @issue = Issue.latest
                @issues = Issue.where(published: true).last(8).reverse
                render @template, :layout => false
            }
            format.text {
                @greeting = 'Hi'
                if current_user and current_user.admin?
                    @user = User.find(params[:id])
                else
                    @user = current_user
                end
                @issue = Issue.latest
                @issues = Issue.where(published: true).last(8).reverse
                render @template, :layout => false
            }
        end
    end

    def user_with_expiry_and_purchases(user)
        expiry = user.expiry_date_including_ios(request)
        # Build up an array of (int) issue numbers that have been purchased for the iOS & Android apps
        purchases = []
        user.purchases.each do |purchase|
            # purchases << {:purchase_date => purchase.purchase_date, :issue_id => purchase.issue_id, :issue_number => purchase.issue.number}
            purchases << purchase.issue.number
        end
        hash = {:username => user.username, :id => user.id, :expiry => expiry, :purchases => purchases}
    end

    def re_sign_in
      sign_out :user
      redirect_to new_user_session_path
    end
end
