# class Admin::UsersController < ApplicationController
class Admin::UsersController < Admin::BaseController
	# Cancan authorisation
  	load_and_authorize_resource

	def index
		@users = User.all(:order => "username")
	end

	def show

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

	def edit

	end

	def update
		if params[:user][:password].blank?
			params[:user].delete(:password)
			params[:user].delete(:password_confirmation)
		end
		if @user.update_attributes(params[:user])
			flash[:notice] = "User has been updated."
			redirect_to admin_user_path
		else
			flash[:alert] = "User has not been updated."
			render :action => "edit"
		end
	end

	def destroy
		if @user == current_user
			flash[:alert] = "You cannot delete yourself!"
		else
		@user.destroy
		flash[:notice] = "user has been deleted."
		end

		redirect_to admin_users_path
	end
end
