class RegistrationsController < Devise::RegistrationsController
  # Cancan authorisation
  # load_and_authorize_resource

  # TOFIX: Allow users to register, but authorize all users with a parent.
  before_action :can_update, :only => [:edit, :update]

  before_action :configure_permitted_parameters, if: :devise_controller?

  prepend_before_action :check_captcha, only: [:create]

  def update
    # NOTE: Duplicated in admin/users_controller.rb
    if not params[:user][:email] == @user.email
      @user.email_updated = DateTime.now
    end

    title_changed = ApplicationHelper.has_been_updated(params[:user][:title], @user.title)
    first_name_changed = ApplicationHelper.has_been_updated(params[:user][:first_name], @user.first_name)
    last_name_changed = ApplicationHelper.has_been_updated(params[:user][:last_name], @user.last_name)
    company_name_changed = ApplicationHelper.has_been_updated(params[:user][:company_name], @user.company_name)
    address_changed = ApplicationHelper.has_been_updated(params[:user][:address], @user.address)
    postal_code_changed = ApplicationHelper.has_been_updated(params[:user][:postal_code], @user.postal_code)
    city_changed = ApplicationHelper.has_been_updated(params[:user][:city], @user.city)
    state_changed = ApplicationHelper.has_been_updated(params[:user][:state], @user.state)
    country_changed = ApplicationHelper.has_been_updated(params[:user][:country], @user.country)
    if title_changed or first_name_changed or last_name_changed or company_name_changed or address_changed or postal_code_changed or city_changed or state_changed or country_changed
      @user.postal_address_updated = DateTime.now
      if not @user.postal_mailable == "Y"
        @user.postal_mailable = "Y"
        params[:user].delete :postal_mailable
        @user.postal_mailable_updated = DateTime.now
      end
    end
    @user.save

    super
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u|
      u.permit(
        :username,
        :email,
        :password,
        :password_confirmation
      )
    }
    devise_parameter_sanitizer.permit(:account_update) { |u|
      u.permit(
        :username,
        :email,
        :current_password,
        :password,
        :password_confirmation,
        :title,
        :first_name,
        :last_name,
        :company_name,
        :address,
        :city,
        :postal_code,
        :state,
        :country,
        :phone
      )
    }
  end

  # To prevent redirect loop when overriding after_sign_in_path_for(resource) in sessions_controller.rb
  def after_sign_up_path_for(resource)
    send_analytics
    # signed_in_root_path(resource)
    # Now use stored path
    after_sign_up_url = stored_location_for(resource)
    if (not after_sign_up_url) or (after_sign_up_url == uk_login_url)
      after_sign_up_url = root_path
    end
    after_sign_up_url
  end

  def after_update_path_for(resource)
    user_path(resource)
  end

  private

  def can_update
    authorize! :update, current_user
  end

  def send_analytics
    log_event('signup', 'complete', 'registration')
    log_fb_event(ENV['FACEBOOK_REGISTRATIONS_CONVERSION'], '0.00')
  end

  def check_captcha
    success = verify_recaptcha(action: 'registration', minimum_score: 0.5, secret_key: ENV['RECAPTCHA_SECRET_KEY_V3'])
    checkbox_success = verify_recaptcha unless success
    if success || checkbox_success
      # Perform action
    else
      if !success
        @show_checkbox_recaptcha = true
      end
      configure_permitted_parameters
      self.resource = resource_class.new sign_up_params
      resource.validate # Look for any other validation errors besides Recaptcha
      set_minimum_password_length

      respond_with_navigational(resource) do
        flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
        render :new
      end
    end
  end

end