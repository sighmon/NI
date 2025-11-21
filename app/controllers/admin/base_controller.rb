class Admin::BaseController < ApplicationController

	# Cancan won't work here, so we use verify_admin
	before_action :verify_admin

	def index
		users_csv = Settings.find_by_var('users_csv')
		if users_csv
			@latest_csv_date = users_csv.updated_at.strftime("digisub-%Y-%m-%d-%H:%M:%S")
		else
			@latest_csv_date = nil
		end

		current_digital_subscribers_csv = Settings.find_by_var('current_digital_subscribers_csv')
		if current_digital_subscribers_csv
			@latest_subscribers_csv_date = current_digital_subscribers_csv.updated_at.strftime("current_subscribers-%Y-%m-%d-%H:%M:%S")
		else
			@latest_subscribers_csv_date = nil
		end

		lapsed_digital_subscribers_csv = Settings.find_by_var('lapsed_digital_subscribers_csv')
		if lapsed_digital_subscribers_csv
			@latest_lapsed_csv_date = lapsed_digital_subscribers_csv.updated_at.strftime("lapsed_subscribers-%Y-%m-%d-%H:%M:%S")
		else
			@latest_lapsed_csv_date = nil
		end

		lapsed_institution_subscribers_csv = Settings.find_by_var('lapsed_institution_subscribers_csv')
		if lapsed_institution_subscribers_csv
			@latest_lapsed_institution_csv_date = lapsed_institution_subscribers_csv.updated_at.strftime("lapsed_institution_subscribers-%Y-%m-%d-%H:%M:%S")
		else
			@latest_lapsed_institution_csv_date = nil
		end

		current_paper_subscribers_csv = Settings.find_by_var('current_paper_subscribers_csv')
		if current_paper_subscribers_csv
			@latest_paper_csv_date = current_paper_subscribers_csv.updated_at.strftime("paper_subscribers-%Y-%m-%d-%H:%M:%S")
		else
			@latest_paper_csv_date = nil
		end

		uk_export_csv = Settings.find_by_var('uk_export_csv')
		if uk_export_csv
			@uk_export_csv_date = uk_export_csv.updated_at.strftime("uk_export-%Y-%m-%d-%H:%M:%S")
		else
			@uk_export_csv_date = nil
		end

		subscriber_stats = Settings.find_by_var('subscriber_stats')
		if subscriber_stats
			@subscriber_stats = subscriber_stats.value
		else
			@subscriber_stats = nil
		end
	end

	def reset_password_instructions_email
		@token = "fake_token"
    @resource = current_user
    @template = 'devise/mailer/reset_password_instructions'
    
    respond_to do |format|
      format.mjml {
				render @template, layout: false
			}
			format.text {
				render @template, layout: false
			}
    end
	end

	def welcome_email
		@greeting = 'Hi'
		@issue = Issue.latest
		@issues = Issue.where(published: true).last(8).reverse
		@user = current_user

		if params[:user_type] == "institution"
			@template = "user_mailer/make_institutional_confirmation"
		else
			@template = "user_mailer/user_signup_confirmation"
		end

		respond_to do |format|
			format.mjml {
				render @template, layout: false
			}
			format.text {
				render @template, layout: false
			}
		end
	end

	def subscription_email
		@greeting = 'Hi'
		@issue = Issue.latest
		@issues = Issue.where(published: true).last(8).reverse
		@subscription = Subscription.first
		@user = @subscription.user
		if params[:user]
			@user = User.find(params[:user])
			@subscription = @user.subscriptions.last
		end

		if params[:subscription_type] == "free"
			@template = "user_mailer/free_subscription_confirmation"
		elsif params[:subscription_type] == "media"
			@template = "user_mailer/media_subscription_confirmation"
		elsif params[:subscription_type] == "cancelled"
			@template = "user_mailer/subscription_cancellation"
		elsif params[:subscription_type] == "cancelled_paypal"
			@template = "user_mailer/subscription_cancelled_via_paypal"
		elsif params[:subscription_type] == "special"
			@template = "issues/email_special"
		else
			@template = "user_mailer/subscription_confirmation"
		end

		respond_to do |format|
			format.mjml {
				render @template, layout: false
			}
			format.text {
				render @template, layout: false
			}
		end
	end

	def magazine_purchase_email
		@greeting = 'Hi'
		@issues = Issue.where(published: true).last(8).reverse
		@purchase = Purchase.last
		@issue = @purchase.issue
		@user = @purchase.user
		@template = "user_mailer/issue_purchase"

		respond_to do |format|
			format.mjml {
				render @template, layout: false
			}
			format.text {
				render @template, layout: false
			}
		end
	end

	def admin_email
		@user = current_user
		@greeting = "Hello"
		@subject = "Example subject."
		@body_text = "Example body with <b>HTML</b> text and <a href='#'>links</a>."
		@template = "user_mailer/admin_email"
		
		respond_to do |format|
			format.mjml {
				render @template, layout: false
			}
		end
	end

	def delete_cache
		if params[:cache] == "all"
			# Delete all cache
			Rails.cache.clear
			logger.info "CACHE: flush_all finished."
		elsif params[:cache] == "blog"
			# Flush timely posts on home page. home_blog_latest and home_web_exclusives
			categories_to_flush = ["/blog/", "/features/web-exclusive/"]
			categories_to_flush.each do |n|
				Category.where(name: n).each do |c|
					c.flush_cache
				end
			end
			Rails.cache.delete("home_blog_latest")
			Rails.cache.delete("home_web_exclusives")
			logger.info "CACHE: flush blog finished."
		elsif params[:cache] == "quick_reads"
			# Flush quick reads cache
			Rails.cache.delete("quick_reads")
			logger.info "CACHE: flush quick_reads finished."
		end
		redirect_back fallback_location: root_path, notice: "Cache cleared: #{params[:cache] || "None"}."
	end

	private

	def verify_admin
		redirect_to root_url unless (current_user and current_user.admin?) or (current_user and current_user.manager?)
	end
	
end
