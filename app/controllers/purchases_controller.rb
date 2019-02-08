class PurchasesController < ApplicationController
  # include ApplicationHelper
  # Cancan authorisation
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    session[:user_return_to] = request.referer
    redirect_to new_user_session_path, :alert => "You need to be logged in to read or purchase articles in this magazine."
  end

  def show
    @greeting = 'Hi'
    @user = current_user
    @issue = @purchase.issue
    @issues = Issue.where(published: true).last(8).reverse
    @template = "user_mailer/issue_purchase"

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
    @issue = Issue.find(params[:issue_id])
    # Issue price moved to Settings.issue_price
    @express_purchase_price = @issue.price
    session[:express_purchase_price] = @express_purchase_price
    response = EXPRESS_GATEWAY.setup_purchase(@express_purchase_price,
      :ip                 => request.remote_ip,
      :return_url         => new_issue_purchase_url(@issue),
      :cancel_return_url  => new_issue_purchase_url(@issue),
      :allow_note         => true,
      :items              => [{:name => "NI #{@issue.number} - #{@issue.title}", :quantity => 1, :description => "New Internationalist Magazine - digital edition", :amount => @express_purchase_price}],
      :currency           => 'AUD'
    )
    redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
  end

  def new
    @user = User.find(current_user.id)
    @purchase = @user.purchases.build(params[:issue])
    @express_token = params[:token]
    @express_payer_id = params[:PayerID]

    @has_token = not(@express_token.blank? or @express_payer_id.blank?)

    if @has_token
      @issue = Issue.find(session[:issue_id_being_purchased])
      retrieve_paypal_express_details(@express_token)
      session[:express_token] = @express_token
      session[:express_payer_id] = @express_payer_id
    else
      @issue = Issue.find(params[:issue_id])
      session[:issue_id_being_purchased] = @issue.id
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @purchase }
    end
  end

  def create
    @issue = Issue.find(session[:issue_id_being_purchased])
    @user = User.find(current_user.id)

    # Make the PayPal purchase
    response = EXPRESS_GATEWAY.purchase(session[:express_purchase_price], express_purchase_options)
    if response.success?
      # FIXME: Work out how to simplify this call.
      @purchase = Purchase.new(:user_id => @user.id, :issue_id => @issue.id)
      # Write purchase date & price to purchase object
      @purchase.price_paid = session[:express_purchase_price]
      @purchase.purchase_date = DateTime.now
      # Save the paypal data to the purchase model
      @purchase.paypal_payer_id = session[:express_payer_id]
      @purchase.paypal_first_name = session[:express_first_name]
      @purchase.paypal_last_name = session[:express_last_name]
    end

    respond_to do |format|
      if response.success? and @purchase.save
        # Email the user a confirmation
        begin
          UserMailer.delay.issue_purchase(@purchase)
          ApplicationHelper.start_delayed_jobs
        rescue Exception
          logger.error "500 - Email server is down..."
        end
        log_fb_event(ENV['FACEBOOK_CHECKOUT_CONVERSION'], (session[:express_purchase_price] / 100.0))
        format.html { redirect_to issue_path(@issue), notice: 'Issue was successfully purchased.' }
        format.json { render json: @purchase, status: :created, location: @purchase }
      else
        format.html { redirect_to issue_path(@issue), notice: "Couldn't purchase this issue." }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def express_purchase_options
    {
    :ip         => request.remote_ip,
    :token      => session[:express_token],
    :payer_id   => session[:express_payer_id],
    :items      => [{:name => "NI #{@issue.number} - #{@issue.title}", :quantity => 1, :description => "New Internationalist Magazine - digital edition", :amount => session[:express_purchase_price]}],
    :currency   => 'AUD'
    }
  end

  def purchase_params
    params.fetch(:purchase, {}).permit(:user_id, :issue_id, :created_at)
  end

end
