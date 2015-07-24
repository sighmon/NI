class PasswordsController < Devise::PasswordsController
  protected

  	# To prevent redirect loop when overriding after_sign_in_path_for(resource) in sessions_controller.rb
    def after_resetting_password_path_for(resource)
      signed_in_root_path(resource)
    end
end