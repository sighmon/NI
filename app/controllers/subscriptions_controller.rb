class SubscriptionsController < ApplicationController
  include SubscriptionsHelper
  # include ApplicationHelper
  # Cancan authorisation
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    session[:user_return_to] = request.referer
    if not current_user
      redirect_to new_user_session_path, :alert => "You need to be logged in to buy a subscription."
    else
      redirect_to (session[:user_return_to] or issues_path), :alert => exception.message
    end
  end

  def show
    @greeting = 'Hi'
    @user = current_user
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse

    if params[:subscription_type] == "free"
      @template = "user_mailer/free_subscription_confirmation"
    elsif params[:subscription_type] == "media"
      @template = "user_mailer/media_subscription_confirmation"
    elsif params[:subscription_type] == "cancelled"
      @template = "user_mailer/subscription_cancellation"
    else
      @template = "user_mailer/subscription_confirmation"
    end

    respond_to do |format|
      format.mjml {
        render @template, :layout => false
      }
      format.text {
        render @template, :layout => false
      }
    end
  end

  def express

    authorize! :update, Subscription
    
    if params[:autodebit] == "1"
      @autodebit = true
    else
      @autodebit = false
    end

    if params[:paper] == "1"
      @paper = true
    else
      @paper = false
    end

    if params[:institution] == "1"
      @institution = true
    else
      @institution = false
    end

    @express_purchase_subscription_duration = params[:duration].to_i
    @express_purchase_price = Subscription.calculate_subscription_price(@express_purchase_subscription_duration, {autodebit: @autodebit, paper: @paper, institution: @institution, special: params[:special]})
    session[:express_autodebit] = @autodebit
    session[:express_paper] = @paper
    session[:express_institution] = @institution
    session[:express_purchase_price] = @express_purchase_price
    session[:express_purchase_subscription_duration] = @express_purchase_subscription_duration

    if @autodebit
      # Autodebit setup
      if @paper == true
        # Paper & digital
        if @institution == true
          payment_description = "#{session[:express_purchase_subscription_duration]} monthly automatic-debit for both a Digital and Paper institution subscription to New Internationalist Magazine."
        else
          payment_description = "#{session[:express_purchase_subscription_duration]} monthly automatic-debit for both a Digital and Paper subscription to New Internationalist Magazine."
        end
      else
        # Just digital
        if @institution == true
          payment_description = "#{session[:express_purchase_subscription_duration]} monthly automatic-debit institution subscription to New Internationalist Digital Edition."
        else
          payment_description = "#{session[:express_purchase_subscription_duration]} monthly automatic-debit subscription to New Internationalist Digital Edition."
        end
      end
      session[:express_purchase_description] = payment_description

      ppr = PayPal::Recurring.new({
        :return_url   => new_subscription_url,
        :cancel_url   => new_subscription_url,
        :description  => payment_description,
        :amount       => (session[:express_purchase_price] / 100),
        :currency     => 'AUD'
      })
      response = ppr.checkout
      redirect_to response.checkout_url if response.valid?
    else
      if @paper == true
        if @institution == true
          payment_description = "New Internationalist Magazine - institution subscription to both the digital edition and the paper edition."
        else
          payment_description = "New Internationalist Magazine - subscription to both the digital edition and the paper edition."
        end
      else
        if @institution == true
          payment_description = "New Internationalist Magazine - institution subscription to the digital edition."
        else
          payment_description = "New Internationalist Magazine - subscription to the digital edition."
        end
      end
      session[:express_purchase_description] = payment_description

      response = EXPRESS_GATEWAY.setup_purchase(@express_purchase_price,
        :ip                 => request.remote_ip,
        :return_url         => new_subscription_url,
        :cancel_return_url  => new_subscription_url,
        :allow_note         => true,
        :items              => [{:name => "#{session[:express_purchase_subscription_duration]} Month Subscription to NI", :quantity => 1, :description => payment_description, :amount => session[:express_purchase_price]}],
        :currency           => 'AUD'
      )
      redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
    end
  end

  def new

    @user = current_user
    @express_token = params[:token]
    @express_payer_id = params[:PayerID]

    @has_token = not(@express_token.blank? or @express_payer_id.blank?)

    if @has_token
      retrieve_paypal_express_details(@express_token, {autodebit: session[:express_autodebit]})
      session[:express_token] = @express_token
      session[:express_payer_id] = @express_payer_id
    else
      logger.info "*** No token. ***"
    end

  end

  def edit
    @user = current_user
    @subscription = Subscription.find(params[:id])
    @cancel_subscription = true
  end

  def create

    payment_complete = false
    notice_message_for_user = "Something went wrong, sorry!"
    @user = current_user
    @subscription = @user.subscriptions.build(:valid_from => (@user.last_subscription.try(:expiry_date) or DateTime.now), :duration => session[:express_purchase_subscription_duration], :purchase_date => DateTime.now)

    if session[:express_autodebit]
      # It's an autodebit, so set that up
      # 1. setup autodebit by requesting payment
      ppr = PayPal::Recurring.new({
        :token       => session[:express_token],
        :payer_id    => session[:express_payer_id],
        :amount      => (session[:express_purchase_price] / 100),
        :ipn_url     => "#{payment_notifications_url}",
        :currency    => 'AUD',
        :description => session[:express_purchase_description]
      })
      response_request = ppr.request_payment

      if response_request.approved? and response_request.completed?
        # 2. create profile & save recurring profile token
        # Set :period to :daily and :frequency to 1 for testing IPN every minute
        ppr = PayPal::Recurring.new({
          :token       => session[:express_token],
          :payer_id    => session[:express_payer_id],
          :amount      => (session[:express_purchase_price] / 100),
          :currency    => 'AUD',
          :description => session[:express_purchase_description],
          :frequency   => session[:express_purchase_subscription_duration], # 1,
          :period      => :monthly, # :daily,
          :reference   => "#{current_user.id}",
          :ipn_url     => "#{payment_notifications_url}",
          :start_at    => (@subscription.valid_from + session[:express_purchase_subscription_duration].months), # Time.now
          :failed      => 1,
          :outstanding => :next_billing
        })

        response_create = ppr.create_recurring_profile
        if not(response_create.profile_id.blank?)
          @subscription.paypal_profile_id = response_create.profile_id
          # If successful, update the user's subscription date.
          # update_subscription_expiry_date
          # Reset refund if they had one in the past
          @subscription.refund = nil

          # TODO: Background task
          # TODO: Check paypal recurring profile id still valid
          # TODO: Setup future update_subscription_expiry_date

          # Save the PayPal data to the @subscription model for receipts
          save_paypal_data_to_subscription_model
          payment_complete = true
        else
          # Why didn't this work? Log it.
          logger.warn "create_recurring_profile failed: #{response_create.params}"
        end
      else
        # Why didn't this work? Log it.
        logger.warn "request_payment failed: #{response_request.params}"
        notice_message_for_user = response_request.params[:L_LONGMESSAGE0]
      end
    else
      # It's a single purchase so make the PayPal purchase
      response = EXPRESS_GATEWAY.purchase(session[:express_purchase_price], express_purchase_options)

      if response.success?
        # If successful, update the user's subscription date.
        # update_subscription_expiry_date
        save_paypal_data_to_subscription_model
        payment_complete = true
      else
        # The user probably hit back and refresh or paypal is broken.
        logger.warn response.params
        notice_message_for_user = response.message
        # redirect_to user_path(current_user), notice: response.message
        # return
      end
    end

    # TODO: implement automatically purchase the current issue

    respond_to do |format|
      if payment_complete and @subscription.save
        # Send the user an email
        begin
          UserMailer.delay.subscription_confirmation(@subscription)
          ApplicationHelper.start_delayed_jobs
          if session[:express_institution]
            # institutional subscription, so send admin an email
            UserMailer.subscription_institution_tell_admin(@subscription.user).deliver
          end
        rescue Exception
          logger.error "500 - Email server is down..."
        end
        log_fb_event(ENV['FACEBOOK_CHECKOUT_CONVERSION'], (session[:express_purchase_price] / 100.0))
        format.html { redirect_to user_path(current_user), notice: 'Subscription was successfully purchased.' }
        format.json { render json: @subscription, status: :created, location: @subscription }
      else
        flash[:error] = notice_message_for_user
        format.html { redirect_to user_path(current_user) }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @user = current_user
    @subscription = Subscription.find(params[:id])
    cancel_complete = false

    if params[:cancel] == 'true'
      if @subscription.is_recurring?
        # user has a recurring subscription
        if cancel_recurring_subscription
          # Find all recurring subscriptions and cancel them.
          all_subscriptions = @user.recurring_subscriptions(@subscription.paypal_profile_id)
          all_subscriptions.each do |s|
            s.expire_subscription
            s.save
            logger.info "Refund for subscription id: #{s.id} is #{s.refund} cents."
            logger.info "Expired Subscription id: #{s.id} - cancel date: #{s.cancellation_date}"
          end
          cancel_complete = true
        else 
          # redirect_to user_path(@user), notice: "Sorry, we couldn't cancel your PayPal recurring subscription, please try again later."
          cancel_complete = false
          logger.warn "Sorry, we couldn't cancel your PayPal recurring subscription, please try again later."
        end
      else
        # user has a normal subscription
        @subscription.expire_subscription
        cancel_complete = true
      end
    else
      # redirect_to user_path(@user), notice: "Not trying to cancel?"
      cancel_complete = false
      logger.warn "Somehow we weren't passed the cancel param."
    end

    if cancel_complete and @subscription.save
      # Send the user an email to confirm the cancellation.
      begin
        UserMailer.delay.subscription_cancellation(@subscription)
        ApplicationHelper.start_delayed_jobs
      rescue Exception
        logger.error "500 - Email server is down..."
      end
      redirect_to user_path(@user), notice: "Subscription was successfully cancelled."
    else
      redirect_to user_path(@user), notice: "Something went wrong in the last step, sorry."
    end

    # TODO: Check with pix that my above fix is okay.

    # respond_to do |format|
    #     if cancel_complete and @subscription.save
    #         format.html { redirect_to user_path(@user), notice: 'Subscription was successfully cancelled.' }
    #         format.json { render json: @subscription, status: :created, location: @subscription }
    #     else
    #         format.html { redirect_to user_path(@user), notice: "Something went wrong in the last step, sorry." }
    #         format.json { render json: @subscription.errors, status: :unprocessable_entity }
    #     end
    # end
  end

  private

  def cancel_recurring_subscription
    ppr = PayPal::Recurring.new(:profile_id => @subscription.paypal_profile_id)
    response = ppr.cancel
    if response.success?
      # Don't nil out paypal recurring profile.
      # @subscription.paypal_profile_id = nil
      session[:express_autodebit] = false
      return true
    else
      return false
    end
  end

  def save_paypal_data_to_subscription_model
    @subscription.paypal_payer_id = session[:express_payer_id]
    @subscription.paypal_email = session[:express_email]
    @subscription.paypal_first_name = session[:express_first_name]
    @subscription.paypal_last_name = session[:express_last_name]
    @subscription.price_paid = session[:express_purchase_price]
    # @subscription.paypal_profile_id also saved for recurring payments earlier
    @subscription.paypal_street1 = session[:express_street1]
    @subscription.paypal_street2 = session[:express_street2]
    @subscription.paypal_city_name = session[:express_city_name]
    @subscription.paypal_state_or_province = session[:express_state_or_province]
    @subscription.paypal_country_name = session[:express_country_name]
    @subscription.paypal_country_code = session[:express_country_code]
    @subscription.paypal_postal_code = session[:express_postal_code]
    @subscription.paper_copy = session[:express_paper]
  end

  def express_purchase_options
    {
    :ip         => request.remote_ip,
    :token      => session[:express_token],
    :payer_id   => session[:express_payer_id],
    :items      => [{:name => "#{session[:express_purchase_subscription_duration]} Month Subscription to NI", :quantity => 1, :description => "New Internationalist Magazine - subscription to the digital edition", :amount => session[:express_purchase_price]}],
    :currency   => 'AUD'
    }
  end

  def subscription_params
    params.fetch(:subscription, {}).permit(:valid_from, :duration, :cancellation_date, :user_id, :paypal_payer_id, :paypal_email, :paypal_profile_id, :paypal_first_name, :paypal_last_name, :refund, :purchase_date, :price_paid, :paper_copy)
  end
  
end
