# class Admin::UsersController < ApplicationController
class Admin::UsersController < Admin::BaseController
	# Cancan authorisation
  	load_and_authorize_resource

	def index
		@users = User.all(:order => "username")
	end

	def new
		@user = User.new
	end

	def create
		@user = User.new(params[:user])
		if @user.save
			flash[:notice] = "User has been created."
			redirect_to admin_users_path
		else
			flash[:alert] = "User has not been created!"
			render :action => "new"
		end
	end
end
