class Admin::BaseController < ApplicationController

	# Cancan authorisation (TODO: not working!)
  	# load_and_authorize_resource

  	before_filter :verify_admin
	private
	def verify_admin
	  redirect_to root_url unless (current_user and current_user.admin?)
	end

	def index
	end
end
