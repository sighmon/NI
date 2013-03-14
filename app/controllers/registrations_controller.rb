class RegistrationsController < Devise::RegistrationsController
	# Cancan authorisation
	# load_and_authorize_resource
	before_filter :can_update

	private

	def can_update
		authorize! :update, current_user
	end
end