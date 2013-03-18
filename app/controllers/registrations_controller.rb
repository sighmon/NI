class RegistrationsController < Devise::RegistrationsController
	# Cancan authorisation
	# load_and_authorize_resource
	
	# TOFIX: Allow users to register, but authorize all users with a parent.
	before_filter :can_update

	private

	def can_update
		if current_user
			authorize! :update, current_user
		end
	end
end