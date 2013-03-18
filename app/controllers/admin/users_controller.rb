# class Admin::UsersController < ApplicationController
class Admin::UsersController < Admin::BaseController
	# Cancan authorisation
  	load_and_authorize_resource

	def index
		@users = User.all(:order => "username")
		@subscribers = @users.select{|s| s.subscriber?}
		@guest_passes = GuestPass.all

		respond_to do |format|
			format.html
			format.csv { render :csv => User.all(:order => :email), :filename => DateTime.now.strftime("digisub-%Y-%m-%d-%H:%M:%S") }
		end
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
		# @subscription = @user.subscription
	end

	def update
		if params[:user][:password].blank?
			params[:user].delete(:password)
			params[:user].delete(:password_confirmation)
		end
		if @user.update_attributes(params[:user])
			# TODO: work out how to update subscription attributes intead of BUILD
			# Can't do this since changing subscription to non-singleton
			# @user.build_subscription(params[:subscription])
			@user.save
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

	def free_subscription
		@user = User.find(params[:user_id])
		@free_subscription = Subscription.create(:user_id => @user.id, :valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => 12, :purchase_date => DateTime.now, :price_paid => 0)

		respond_to do |format|
			if @free_subscription.save
			    # Send the user an email
				UserMailer.free_subscription_confirmation(User.find(params[:user_id])).deliver
				format.html { redirect_to admin_user_path(@user), notice: 'Free subscription was successfully created.' }
				format.json { render json: @free_subscription, status: :created, location: @free_subscription }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't add a free subscription, sorry." }
				format.json { render json: @free_subscription.errors, status: :unprocessable_entity }
			end
		end
	end

	def media_subscription
		@user = User.find(params[:user_id])
		@free_subscription = Subscription.create(:user_id => @user.id, :valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => 120, :purchase_date => DateTime.now, :price_paid => 0)

		respond_to do |format|
			if @free_subscription.save
			    # Send the user an email
				UserMailer.media_subscription_confirmation(User.find(params[:user_id])).deliver
				format.html { redirect_to admin_user_path(@user), notice: 'Free media 10yr subscription was successfully created.' }
				format.json { render json: @free_subscription, status: :created, location: @free_subscription }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't add a media subscription, sorry." }
				format.json { render json: @free_subscription.errors, status: :unprocessable_entity }
			end
		end
	end

end
