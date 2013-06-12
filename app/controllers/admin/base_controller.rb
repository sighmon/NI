class Admin::BaseController < ApplicationController

	# Cancan won't work here, so we use verify_admin
  	before_filter :verify_admin
	private
	def verify_admin
	  redirect_to root_url unless (current_user and current_user.admin?)
	end

	def index
	end

  
end
