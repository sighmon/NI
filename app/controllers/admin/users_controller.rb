# class Admin::UsersController < ApplicationController
class Admin::UsersController < Admin::BaseController
	# Cancan authorisation
	load_and_authorize_resource

	# For User sorting
	# User sorting now in the model self.sorted_by
	helper_method :sort_column, :sort_direction

	def index
		if params[:users_per_page].present?
			users_per_page = params[:users_per_page]
		else
			users_per_page = Settings.users_pagination
		end
		@pagy, @users = pagy(User.sorted_by(params[:sort], params[:direction]))
		@total_users = User.count
		@uk_users = User.select{|uk| uk.uk_user?}
		@subscribers_total = User.select{|s| s.subscriber?}
		@institutions = User.select{|i| i.institution}
		@students = User.select{|s| s.parent}
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
		@user = User.new(user_params)
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

		# NOTE: Duplicated in registrations_controller.rb
		# Update @user details updated at fields
		if not params[:user][:email] == @user.email
			@user.email_updated = DateTime.now
		end

		if ApplicationHelper.has_been_updated(params[:user][:postal_mailable], @user.postal_mailable)
			@user.postal_mailable_updated = DateTime.now
		end

		if ApplicationHelper.has_been_updated(params[:user][:email_opt_in], @user.email_opt_in)
			@user.email_opt_in_updated = DateTime.now
		end

		title_changed = ApplicationHelper.has_been_updated(params[:user][:title], @user.title)
		first_name_changed = ApplicationHelper.has_been_updated(params[:user][:first_name], @user.first_name)
		last_name_changed = ApplicationHelper.has_been_updated(params[:user][:last_name], @user.last_name)
		company_name_changed = ApplicationHelper.has_been_updated(params[:user][:company_name], @user.company_name)
		address_changed = ApplicationHelper.has_been_updated(params[:user][:address], @user.address)
		postal_code_changed = ApplicationHelper.has_been_updated(params[:user][:postal_code], @user.postal_code)
		city_changed = ApplicationHelper.has_been_updated(params[:user][:city], @user.city)
		state_changed = ApplicationHelper.has_been_updated(params[:user][:state], @user.state)
		country_changed = ApplicationHelper.has_been_updated(params[:user][:country], @user.country)
		if title_changed or first_name_changed or last_name_changed or company_name_changed or address_changed or postal_code_changed or city_changed or state_changed or country_changed
			@user.postal_address_updated = DateTime.now
			if not @user.postal_mailable == "Y"
        @user.postal_mailable = "Y"
        params[:user].delete :postal_mailable
        @user.postal_mailable_updated = DateTime.now
      end
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

		redirect_to admin_root_path
	end

	def free_subscription
		# Give a user a free 1 year subscription
		@user = User.find(params[:user_id])
		@free_subscription = Subscription.create(:user_id => @user.id, :valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => 12, :purchase_date => DateTime.now, :price_paid => 0)

		respond_to do |format|
			if @free_subscription.save
			    # Send the user an email
				UserMailer.delay.free_subscription_confirmation(User.find(params[:user_id]), 12)
				ApplicationHelper.start_delayed_jobs
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
				UserMailer.delay.media_subscription_confirmation(User.find(params[:user_id]))
				ApplicationHelper.start_delayed_jobs
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
		    UserMailer.delay.make_institutional_confirmation(User.find(params[:user_id]))
        ApplicationHelper.start_delayed_jobs
				format.html { redirect_to admin_user_path(@user), notice: "#{@user.username} is now an institutional user." }
				format.json { render json: @user, status: :created, location: @user }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't make this user an institutional user, sorry." }
				format.json { render json: @user.errors, status: :unprocessable_entity }
			end
		end
	end

	def add_subscription
		# Give a free x month subscription
		@user = User.find(params[:user_id])
		@paper_copy = nil
		@paper_only = nil
		@institution = nil
		@price_paid = nil
		
		if request.post?
			@number_of_months = params["/admin/users/#{@user.id}/add_subscription"][:number_of_months]
			send_email = params["/admin/users/#{@user.id}/add_subscription"][:send_email]
			@paper_copy = params["/admin/users/#{@user.id}/add_subscription"][:paper_copy]
			@paper_only = params["/admin/users/#{@user.id}/add_subscription"][:paper_only]
		else
			@number_of_months = params[:number_of_months]
			send_email = params[:send_email]
			@institution = params[:institution]
			@price_paid = params[:price_paid]
			@paper_copy = params[:paper_copy]
			@paper_only = params[:paper_only]
		end

		if @institution == "1"
			@user.institution = true
			@user.save
		end

		# Calculate valid_from correctly for paper_only subscriptions
		if @paper_only == "1" or @paper_only == "true"
			@valid_from = (@user.last_paper_subscription.try(:expiry_date_paper_only) or DateTime.now)
		elsif @paper_copy == "1" or @paper_copy == "true"
			@valid_from = (@user.last_paper_copy_subscription.try(:expiry_date_paper_copy) or DateTime.now)
		else
			@valid_from = (@user.last_subscription.try(:expiry_date) or DateTime.now)
		end

		@free_subscription = Subscription.create(
			:user_id => @user.id,
			:valid_from => @valid_from,
			:duration => @number_of_months,
			:purchase_date => DateTime.now,
			:price_paid => @price_paid,
			:paper_copy => @paper_copy,
			:paper_only => @paper_only
		)

		respond_to do |format|
			if @free_subscription.save
				# Send a confirmation email?
				if send_email == "1"
					UserMailer.delay.free_subscription_confirmation(User.find(params[:user_id]), @number_of_months)
					ApplicationHelper.start_delayed_jobs
				end
				format.html { redirect_to admin_user_path(@user), notice: "Free #{@number_of_months} month subscription was successfully created." }
				format.json { render json: @free_subscription, status: :created, location: @free_subscription }
			else
				format.html { redirect_to admin_user_path(@user), notice: "Couldn't create the free subscription, sorry." }
				format.json { render json: @free_subscription.errors, status: :unprocessable_entity }
			end
		end
	end

	def update_csv
		if params[:type] == 'users_all'
			begin
				Settings.destroy('users_csv')
			rescue
				# Pass
			end
			User.delay.update_admin_users_csv
		elsif params[:type] == 'users_current'
			begin
				Settings.destroy('current_digital_subscribers_csv')
			rescue
				# Pass
			end
			User.delay.update_current_digital_subscribers_csv
		elsif params[:type] == 'users_lapsed'
			begin
				Settings.destroy('lapsed_digital_subscribers_csv')
			rescue
				# Pass
			end
			User.delay.update_lapsed_digital_subscribers_csv
		elsif params[:type] == 'institutions_lapsed'
			begin
				Settings.destroy('lapsed_institution_subscribers_csv')
			rescue
				# Pass
			end
			User.delay.update_lapsed_institution_subscribers_csv
		elsif params[:type] == 'users_paper'
			begin
				Settings.destroy('current_paper_subscribers_csv')
			rescue
				# Pass
			end
			User.delay.update_current_paper_subscribers_csv
		elsif params[:type] == 'subscriber_stats'
			begin
				Settings.destroy('subscriber_stats')
			rescue
				# Pass
			end
			User.delay.update_subscriber_stats
		end
		view_context.start_delayed_jobs
		redirect_to admin_root_path, notice: 'Refreshing CSV...'
	end

	def download_csv
		if params[:type] == 'users_all'
			csv = Settings.find_by_var('users_csv')
			csv_name = 'digisub'
		elsif params[:type] == 'users_current'
			csv = Settings.find_by_var('current_digital_subscribers_csv')
			csv_name = 'current_subscribers'
		elsif params[:type] == 'users_lapsed'
			csv = Settings.find_by_var('lapsed_digital_subscribers_csv')
			csv_name = 'lapsed_subscribers'
		elsif params[:type] == 'institutions_lapsed'
			csv = Settings.find_by_var('lapsed_institution_subscribers_csv')
			csv_name = 'lapsed_institutions'
		elsif params[:type] == 'users_paper'
			csv = Settings.find_by_var('current_paper_subscribers_csv')
			csv_name = 'paper_subscribers'
		end
		respond_to do |format|
			format.csv {
				# response.headers['Content-Disposition'] = 'attachment; filename="' + csv.updated_at.strftime("digisub-%Y-%m-%d-%H:%M:%S") + '.csv"'
				send_data csv.value, type: Mime[:csv], disposition: 'attachment', filename: csv.updated_at.strftime("#{csv_name}-%Y-%m-%d-%H:%M:%S") + ".csv"
			}
		end
	end

	def search
		@query = params[:query]
		if @query.blank?
			@users = []
		else
			@users = User.where("email ~* :query or username ~* :query or first_name ~* :query or last_name ~* :query or CONCAT(first_name,' ', last_name) ~* :query or company_name ~* :query or address ~* :query or comments ~* :query or replace(phone, ' ', '') ~* :query or phone ~* :query", { query: @query }).sorted_by(params[:sort], params[:direction])
		end
		respond_to do |format|
			format.html
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
    params.require(:user).permit(:issue_ids, :login, :username, :expirydate, :subscriber, :email, :password, :password_confirmation, :remember_me, :title, :first_name, :last_name, :company_name, :address, :postal_code, :city, :state, :country, :phone, :postal_mailable, :email_opt_in, :paper_renewals, :digital_renewals, :subscriptions_order_total, :products_order_total, :annuals_buyer, :comments)
  end

end
