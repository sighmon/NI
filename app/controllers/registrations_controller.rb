class RegistrationsController < Devise::RegistrationsController
  # Cancan authorisation
  # load_and_authorize_resource

  # TOFIX: Allow users to register, but authorize all users with a parent.
  before_action :can_update, :only => [:edit, :update]

  before_action :configure_permitted_parameters, if: :devise_controller?

  prepend_before_action :check_captcha, only: [:create]

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :current_password, :password, :password_confirmation) }
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
    signed_in_root_path(resource)
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
    unless verify_recaptcha
      self.resource = resource_class.new sign_up_params
      resource.validate # Look for any other validation errors besides Recaptcha
      set_minimum_password_length
      respond_with resource
    end 
  end

end