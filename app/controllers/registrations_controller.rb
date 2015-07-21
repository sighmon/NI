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

  private

  def can_update
    authorize! :update, current_user
  end
end