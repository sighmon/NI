class RegistrationsController < Devise::RegistrationsController
  # Cancan authorisation
  # load_and_authorize_resource

  # TOFIX: Allow users to register, but authorize all users with a parent.
  before_filter :can_update, :only => [:edit, :update]

  before_filter :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :current_password, :password, :password_confirmation) }
  end

  # To prevent redirect loop when overriding after_sign_in_path_for(resource) in sessions_controller.rb
  def after_sign_up_path_for(resource)
    send_analytics
    signed_in_root_path(resource)
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

end