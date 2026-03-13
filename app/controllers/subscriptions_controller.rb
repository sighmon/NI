class SubscriptionsController < ApplicationController
  include SubscriptionsHelper
  # include ApplicationHelper
  # Cancan authorisation
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    session[:user_return_to] = request.referer
    if not current_user
      redirect_to new_user_session_path, alert: "You need to be logged in to buy a subscription."
    else
      redirect_to (session[:user_return_to] or issues_path), alert: exception.message
    end
  end

  def show
    @greeting = 'Hi'
    @user = @subscription.user
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse

    if params[:subscription_type] == "free"
      @template = "user_mailer/free_subscription_confirmation"
    elsif params[:subscription_type] == "media"
      @template = "user_mailer/media_subscription_confirmation"
    elsif params[:subscription_type] == "cancelled"
      @template = "user_mailer/subscription_cancellation"
    elsif params[:subscription_type] == "cancelled_paypal"
      @template = "user_mailer/subscription_cancelled_via_paypal"
    else
      @template = "user_mailer/subscription_confirmation"
    end

    respond_to do |format|
      format.html {
        render @template
      }
      format.mjml {
        render @template, layout: false
      }
      format.text {
        render @template, layout: false
      }
    end
  end

  def express
    redirect_to new_subscription_path(subscription_selection_params.to_h)
  end

  def new

    @user = current_user
    @subscription_options = SubscriptionCheckoutOption.available
    @selected_subscription_option = SubscriptionCheckoutOption.from_params(subscription_selection_params)
    @paypal_sdk_url = if @selected_subscription_option.present?
      PaypalConfiguration.javascript_sdk_src(
        currency: 'AUD',
        intent: (@selected_subscription_option.autodebit? ? 'subscription' : nil),
        vault: @selected_subscription_option.autodebit?
      )
    end

  end

  def edit
    @user = current_user
    @subscription = Subscription.find(params[:id])
    @cancel_subscription = true
  end

  def create
    @user = current_user
    option = selected_subscription_option!
    capture = paypal_client.capture_order(params.require(:paypal_order_id))
    validate_captured_subscription_order!(capture, option)
    @subscription = build_subscription_for(option)

    assign_subscription_buyer_details(
      payer: capture["payer"],
      shipping: capture.dig("purchase_units", 0, "shipping")
    )

    respond_to do |format|
      if capture_completed?(capture) && @subscription.save
        deliver_subscription_confirmation
        log_fb_event(ENV['FACEBOOK_CHECKOUT_CONVERSION'], (option.price_cents / 100.0))
        format.html { redirect_to user_path(current_user), notice: 'Subscription was successfully purchased.' }
        format.json { render json: { redirect_url: user_path(current_user) }, status: :created }
      else
        format.html { redirect_to user_path(current_user), alert: 'Something went wrong, sorry.' }
        format.json { render json: { error: 'Could not complete this PayPal order.' }, status: :unprocessable_content }
      end
    end
  rescue PaypalRest::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def paypal_order
    authorize! :create, Subscription

    option = selected_subscription_option!
    order = paypal_client.create_order(
      {
        intent: "CAPTURE",
        application_context: {
          brand_name: ENV["APP_NAME"],
          shipping_preference: (option.requires_shipping? ? "GET_FROM_FILE" : "NO_SHIPPING"),
          user_action: "PAY_NOW"
        },
        purchase_units: [
          {
            custom_id: "subscription-#{option.key}-user-#{current_user.id}",
            description: option.description,
            amount: {
              currency_code: "AUD",
              value: option.price_value,
              breakdown: {
                item_total: {
                  currency_code: "AUD",
                  value: option.price_value
                }
              }
            },
            items: [
              {
                name: option.purchase_unit_name,
                description: option.description,
                quantity: "1",
                unit_amount: {
                  currency_code: "AUD",
                  value: option.price_value
                }
              }
            ]
          }.compact
        ]
      }
    )

    render json: { id: order.fetch("id") }
  rescue PaypalRest::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def paypal_subscription
    authorize! :create, Subscription

    option = selected_subscription_option!
    plan = PaypalRest::PlanCatalog.new(client: paypal_client).ensure_plan!(option)
    subscription = paypal_client.create_subscription(
      {
        plan_id: plan.fetch("id"),
        custom_id: "subscription-#{option.key}-user-#{current_user.id}",
        application_context: {
          brand_name: ENV["APP_NAME"],
          locale: "en-AU",
          shipping_preference: (option.requires_shipping? ? "GET_FROM_FILE" : "NO_SHIPPING"),
          user_action: "SUBSCRIBE_NOW",
          return_url: user_url(current_user),
          cancel_url: new_subscription_url(option.to_h)
        }
      }
    )

    render json: { id: subscription.fetch("id") }
  rescue PaypalRest::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def paypal_subscription_approval
    authorize! :create, Subscription

    option = selected_subscription_option!
    details = paypal_client.show_subscription(params.require(:paypal_subscription_id))
    validate_approved_subscription!(details, option)
    @user = current_user
    valid_from = (@user.last_subscription.try(:expiry_date) || DateTime.now)
    @subscription = @user.subscriptions.find_or_initialize_by(paypal_profile_id: details.fetch("id"))
    was_new_record = @subscription.new_record?
    @subscription.assign_attributes(
      valid_from: valid_from,
      duration: option.duration,
      purchase_date: DateTime.now,
      price_paid: option.price_cents,
      paper_copy: option.paper?,
      paper_only: option.paper_only?
    )

    assign_subscription_details_from_paypal(details)

    if @subscription.save
      deliver_subscription_confirmation if was_new_record
      log_fb_event(ENV['FACEBOOK_CHECKOUT_CONVERSION'], (option.price_cents / 100.0))
      render json: { redirect_url: user_path(current_user) }, status: :created
    else
      render json: { error: @subscription.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  rescue PaypalRest::Error => e
    render json: { error: e.message }, status: :unprocessable_content
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
    #         format.json { render json: @subscription.errors, status: :unprocessable_content }
    #     end
    # end
  end

  private

  def cancel_recurring_subscription
    paypal_client.cancel_subscription(@subscription.paypal_profile_id, reason: "Cancelled by subscriber")
    true
  rescue PaypalRest::Error
    false
  end

  def subscription_params
    params.fetch(:subscription, {}).permit(:valid_from, :duration, :cancellation_date, :user_id, :paypal_payer_id, :paypal_email, :paypal_profile_id, :paypal_first_name, :paypal_last_name, :refund, :purchase_date, :price_paid, :paper_copy, :paper_only)
  end

  def subscription_selection_params
    params.slice(:duration, :autodebit, :paper, :paper_only, :institution, :special)
  end

  def selected_subscription_option!
    option = SubscriptionCheckoutOption.from_params(subscription_selection_params)
    raise PaypalRest::Error, "Unsupported subscription option." if option.blank?

    option
  end

  def build_subscription_for(option)
    @user.subscriptions.build(
      valid_from: (@user.last_subscription.try(:expiry_date) || DateTime.now),
      duration: option.duration,
      purchase_date: DateTime.now,
      price_paid: option.price_cents,
      paper_copy: option.paper?,
      paper_only: option.paper_only?
    )
  end

  def assign_subscription_details_from_paypal(details)
    subscriber = details.fetch("subscriber", {})
    shipping_address = subscriber.dig("shipping_address", "address") || {}
    shipping_name = subscriber.dig("shipping_address", "name", "full_name")
    first_name, last_name = split_name(shipping_name.presence || [subscriber.dig("name", "given_name"), subscriber.dig("name", "surname")].compact.join(" "))

    @subscription.paypal_profile_id = details["id"]
    @subscription.paypal_payer_id = subscriber["payer_id"]
    @subscription.paypal_email = subscriber["email_address"]
    @subscription.paypal_first_name = subscriber.dig("name", "given_name").presence || first_name
    @subscription.paypal_last_name = subscriber.dig("name", "surname").presence || last_name
    assign_shipping_details(shipping_address)
    update_user_address_from_subscription
  end

  def assign_subscription_buyer_details(payer:, shipping:)
    @subscription.paypal_payer_id = payer["payer_id"]
    @subscription.paypal_email = payer["email_address"]
    @subscription.paypal_first_name = payer.dig("name", "given_name")
    @subscription.paypal_last_name = payer.dig("name", "surname")
    assign_shipping_details((shipping || {})["address"] || {})
    update_user_address_from_subscription
  end

  def assign_shipping_details(address)
    @subscription.paypal_street1 = address["address_line_1"]
    @subscription.paypal_street2 = address["address_line_2"]
    @subscription.paypal_city_name = address["admin_area_2"]
    @subscription.paypal_state_or_province = address["admin_area_1"]
    @subscription.paypal_country_name = ISO3166::Country[address["country_code"]].try(:name)
    @subscription.paypal_country_code = address["country_code"]
    @subscription.paypal_postal_code = address["postal_code"]
  end

  def update_user_address_from_subscription
    return unless @user.address.blank?

    @user.first_name = @subscription.paypal_first_name
    @user.last_name = @subscription.paypal_last_name
    @user.address = @subscription.paypal_street1
    @user.city = @subscription.paypal_city_name
    @user.postal_code = @subscription.paypal_postal_code
    @user.state = @subscription.paypal_state_or_province
    @user.country = @subscription.paypal_country_code
    @user.postal_mailable = 'Y'
    @user.email_opt_in = 'M'
    @user.paper_renewals = 'Y'
    @user.digital_renewals = 'Y'
    @user.save
  end

  def deliver_subscription_confirmation
    begin
      UserMailer.delay.subscription_confirmation(@subscription)
      ApplicationHelper.start_delayed_jobs
    rescue Exception
      logger.error "500 - Email server is down..."
    end
  end

  def paypal_client
    @paypal_client ||= PaypalRest::Client.new
  end

  def capture_completed?(capture)
    capture.dig("status") == "COMPLETED" ||
      capture.dig("purchase_units", 0, "payments", "captures", 0, "status") == "COMPLETED"
  end

  def split_name(full_name)
    parts = full_name.to_s.split
    [parts.first, parts[1..].to_a.join(" ")]
  end

  def validate_captured_subscription_order!(capture, option)
    purchase_unit = capture.fetch("purchase_units", []).first || {}
    capture_amount = purchase_unit.dig("payments", "captures", 0, "amount")

    raise PaypalRest::Error, "PayPal order did not match the selected subscription." unless purchase_unit["custom_id"] == expected_subscription_custom_id(option)
    raise PaypalRest::Error, "PayPal order did not match the selected subscription." unless paypal_amount_matches?(purchase_unit["amount"], option.price_cents)
    if capture_amount.present?
      raise PaypalRest::Error, "PayPal order did not match the selected subscription." unless paypal_amount_matches?(capture_amount, option.price_cents)
    end
  end

  def validate_approved_subscription!(details, option)
    expected_plan_id = PaypalRest::PlanCatalog.new(client: paypal_client).ensure_plan!(option).fetch("id")

    raise PaypalRest::Error, "PayPal subscription did not match the selected subscription." unless details["custom_id"] == expected_subscription_custom_id(option)
    raise PaypalRest::Error, "PayPal subscription did not match the selected subscription." unless details["plan_id"] == expected_plan_id
  end

  def expected_subscription_custom_id(option)
    "subscription-#{option.key}-user-#{current_user.id}"
  end

  def paypal_amount_matches?(amount_hash, expected_cents)
    return false unless amount_hash.is_a?(Hash)
    return false unless amount_hash["currency_code"] == "AUD"

    amount_hash["value"].to_d == (expected_cents.to_d / 100)
  end

end
