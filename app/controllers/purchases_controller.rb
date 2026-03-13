class PurchasesController < ApplicationController
  include ApplicationHelper
  # Cancan authorisation
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    session[:user_return_to] = request.referer
    redirect_to new_user_session_path, alert: "You need to be logged in to read or purchase articles in this magazine."
  end

  def show
    @greeting = 'Hi'
    @user = @purchase.user
    @issue = @purchase.issue
    @issues = Issue.where(published: true).last(8).reverse
    @template = "user_mailer/issue_purchase"

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
    redirect_to new_issue_purchase_path(params[:issue_id])
  end

  def new
    @user = User.find(current_user.id)
    @purchase = @user.purchases.build(params[:issue])
    @issue = Issue.find(params[:issue_id])
    @paypal_sdk_url = PaypalConfiguration.javascript_sdk_src(currency: 'AUD')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @purchase }
    end
  end

  def paypal_order
    authorize! :create, Purchase

    issue = Issue.find(params[:issue_id])
    order = paypal_client.create_order(
      {
        intent: "CAPTURE",
        application_context: {
          brand_name: ENV["APP_NAME"],
          shipping_preference: "NO_SHIPPING",
          user_action: "PAY_NOW"
        },
        purchase_units: [
          {
            custom_id: "issue-#{issue.id}-user-#{current_user.id}",
            description: "NI #{issue.number} - #{issue.title}",
            amount: {
              currency_code: "AUD",
              value: format("%.2f", issue.price / 100.0),
              breakdown: {
                item_total: {
                  currency_code: "AUD",
                  value: format("%.2f", issue.price / 100.0)
                }
              }
            },
            items: [
              {
                name: "NI #{issue.number} - #{issue.title}",
                description: "New Internationalist Magazine - digital edition",
                quantity: "1",
                unit_amount: {
                  currency_code: "AUD",
                  value: format("%.2f", issue.price / 100.0)
                }
              }
            ]
          }
        ]
      }
    )

    render json: { id: order.fetch("id") }
  rescue PaypalRest::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def create
    @issue = Issue.find(params[:issue_id])
    @user = User.find(current_user.id)
    capture = paypal_client.capture_order(params.require(:paypal_order_id))
    validate_captured_issue_order!(capture, @issue)

    @purchase = Purchase.new(user_id: @user.id, issue_id: @issue.id)
    @purchase.price_paid = @issue.price
    @purchase.purchase_date = DateTime.now
    @purchase.paypal_payer_id = capture.dig("payer", "payer_id")
    @purchase.paypal_first_name = capture.dig("payer", "name", "given_name")
    @purchase.paypal_last_name = capture.dig("payer", "name", "surname")

    payment_complete = capture_completed?(capture)

    respond_to do |format|
      if payment_complete && @purchase.save
        # Email the user a confirmation
        begin
          UserMailer.delay.issue_purchase(@purchase)
          ApplicationHelper.start_delayed_jobs
        rescue Exception
          logger.error "500 - Email server is down..."
        end
        log_fb_event(ENV['FACEBOOK_CHECKOUT_CONVERSION'], (@issue.price / 100.0))
        format.html { redirect_to issue_path(@issue), notice: 'Issue was successfully purchased.' }
        format.json { render json: { redirect_url: issue_path(@issue) }, status: :created }
      else
        format.html { redirect_to issue_path(@issue), notice: "Couldn't purchase this issue." }
        format.json { render json: { error: "Could not complete this PayPal order." }, status: :unprocessable_content }
      end
    end
  rescue PaypalRest::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def purchase_params
    params.fetch(:purchase, {}).permit(:user_id, :issue_id, :created_at)
  end

  def paypal_client
    @paypal_client ||= PaypalRest::Client.new
  end

  def capture_completed?(capture)
    capture.dig("status") == "COMPLETED" ||
      capture.dig("purchase_units", 0, "payments", "captures", 0, "status") == "COMPLETED"
  end

  def validate_captured_issue_order!(capture, issue)
    purchase_unit = capture.fetch("purchase_units", []).first || {}
    capture_amount = purchase_unit.dig("payments", "captures", 0, "amount")

    raise PaypalRest::Error, "PayPal order did not match the selected issue." unless purchase_unit["custom_id"] == expected_issue_custom_id(issue)
    raise PaypalRest::Error, "PayPal order did not match the selected issue." unless paypal_amount_matches?(purchase_unit["amount"], issue.price)
    if capture_amount.present?
      raise PaypalRest::Error, "PayPal order did not match the selected issue." unless paypal_amount_matches?(capture_amount, issue.price)
    end
  end

  def expected_issue_custom_id(issue)
    "issue-#{issue.id}-user-#{current_user.id}"
  end

  def paypal_amount_matches?(amount_hash, expected_cents)
    return false unless amount_hash.is_a?(Hash)
    return false unless amount_hash["currency_code"] == "AUD"

    amount_hash["value"].to_d == (expected_cents.to_d / 100)
  end

end
