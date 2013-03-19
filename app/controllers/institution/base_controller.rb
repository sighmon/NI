class Institution::BaseController < ApplicationController

	# Cancan won't work here, so we use verify_institution
  	before_filter :verify_institution
	private
	def verify_institution
	  redirect_to root_url unless (current_user and current_user.institution?)
	end

	def index
	end
end
