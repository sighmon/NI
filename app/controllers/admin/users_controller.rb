# class Admin::UsersController < ApplicationController
class Admin::UsersController < Admin::BaseController
	# Cancan authorisation
	load_and_authorize_resource

	# For User sorting
	helper_method :sort_column, :sort_direction

	def index
		@users = User.order(sort_column + " " + sort_direction)
		@uk_users = @users.select{|uk| uk.uk_user?}
		@subscribers_total = @users.select{|s| s.subscriber?}
		@institutions = @users.select{|i| i.institution}
		@students = @users.select{|s| s.parent}
		@subscribers = @subscribers_total - @students - @institutions
		@guest_passes = GuestPass.all

		respond_to do |format|
			format.html
			# CSV information that's included is in the User model under comma
			format.csv { render :csv => User.order(:email).all, :filename => DateTime.now.strftime("digisub-%Y-%m-%d-%H:%M:%S") }
		end
	end

	def show
		@payment_notifications = @user.payment_notifications
	end

	def become
		return unless current_user.admin?
		sign_in(:user, User.find(params[:user_id]))
		redirect_to user_url(params[:user_id])
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
		# Hacky way to save the ip_whitelist without having it in attribute_accessible
		if params[:user].has_key?(:ip_whitelist)
			@user.update_attribute(:ip_whitelist, params[:user][:ip_whitelist])
			params[:user].delete(:ip_whitelist)
		end
		if @user.update_attributes(user_params)
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
		# Give a user a free 1 year subscription
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

	def crowdfunding_subscription
		# Give a user a free subscription for donating to our crowdfunding campaign
		@user = User.find(params[:user_id])
		@number_of_months = params[:number_of_months]
		@free_subscription = Subscription.create(:user_id => @user.id, :valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => @number_of_months, :purchase_date => DateTime.now, :price_paid => 0)

		respond_to do |format|
			if @free_subscription.save
			    # Send the user an email
				UserMailer.crowdfunding_subscription_confirmation(User.find(params[:user_id]), params[:number_of_months]).deliver
				format.html { redirect_to admin_user_path(@user), notice: "Free #{params[:number_of_months]} month crowdfunding subscription was successfully created." }
				format.json { render json: @free_subscription, status: :created, location: @free_subscription }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't add the crowdfunding free subscription, sorry." }
				format.json { render json: @free_subscription.errors, status: :unprocessable_entity }
			end
		end
	end

	def media_subscription
		# Give a user a free 10 year subscription
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

	def make_institutional
		@user = User.find(params[:user_id])
		@user.institution = true

		respond_to do |format|
			if @user.save and @user.institution
			    # Send the institutional user an email
				UserMailer.make_institutional_confirmation(User.find(params[:user_id])).deliver
				format.html { redirect_to admin_user_path(@user), notice: "#{@user.username} is now an institutional user." }
				format.json { render json: @user, status: :created, location: @user }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't make this user an institutional user, sorry." }
				format.json { render json: @user.errors, status: :unprocessable_entity }
			end
		end
	end

	def free_silent_subscription
		# Give a free x month subscription, DOESN'T SEND EMAIL CONFIRMATION
		@user = User.find(params[:user_id])
		if request.post?
			@number_of_months = params["/admin/users/#{@user.id}/free_silent_subscription"][:number_of_months]
		else
			@number_of_months = params[:number_of_months]
		end

		@free_subscription = Subscription.create(:user_id => @user.id, :valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => @number_of_months, :purchase_date => DateTime.now, :price_paid => 0)

		respond_to do |format|
			if @free_subscription.save
			    # Don't send a confirmation email.
				format.html { redirect_to admin_user_path(@user), notice: "Free #{@number_of_months} month subscription was successfully created." }
				format.json { render json: @free_subscription, status: :created, location: @free_subscription }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't create the free subscription, sorry." }
				format.json { render json: @free_subscription.errors, status: :unprocessable_entity }
			end
		end
	end

	private
  
  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "created_at"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  def user_params
    params.require(:user).permit(:issue_ids, :login, :username, :expirydate, :subscriber, :email, :password, :password_confirmation, :remember_me)
  end

end
