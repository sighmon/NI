class ApplicationController < ActionController::Base
  protect_from_forgery
  # Send the access denied pages to root with a nice message
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to issues_path, :alert => exception.message
  end

  # Save this page location to session
  after_filter :store_location

  private

  def current_ability
    @current_ability ||= Ability.new(current_user, params[:utm_source])
  end

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  def retrieve_paypal_express_details(token, options = {})
    autodebit = options[:autodebit] or false
    if autodebit
        ppr = PayPal::Recurring.new(:token => token)
        details = ppr.checkout_details
    else
        details = EXPRESS_GATEWAY.details_for(token)
    end
    # logger.info "******"
    # logger.info details.params
    # logger.info "******"
    session[:express_payer_id] = details.payer_id
    session[:express_email] = details.email
    session[:express_first_name] = details.params["first_name"]
    session[:express_last_name] = details.params["last_name"]
    session[:express_street1] = details.params["street1"]
    session[:express_street2] = details.params["street2"]
    session[:express_city_name] = details.params["city_name"]
    session[:express_state_or_province] = details.params["state_or_province"]
    session[:express_country_name] = details.params["country_name"]
    session[:express_postal_code] = details.params["postal_code"]
  end

end
