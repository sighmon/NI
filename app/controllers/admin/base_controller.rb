class Admin::BaseController < ApplicationController

	# Cancan won't work here, so we use verify_admin
	before_filter :verify_admin

	def index
		value = Settings.find_by_var('users_csv')
		if value
			@latest_csv_date = value.updated_at.strftime("digisub-%Y-%m-%d-%H:%M:%S")
		else
			@latest_csv_date = nil
		end
	end

	def email_signup
		@greeting = 'Hi'
		@user = current_user
		@issue = Issue.latest
		@issues = Issue.last(8).reverse

		respond_to do |format|
      format.mjml { render "user_mailer/user_signup_confirmation", :layout => false }
      format.text { render "user_mailer/user_signup_confirmation", :layout => false }
    end
	end

	private

	def verify_admin
	  redirect_to root_url unless (current_user and current_user.admin?)
	end
  
end
