class ApplicationController < ActionController::Base

  before_action :auto_signin_ip

  before_action :configure_permitted_parameters, if: :devise_controller?

  protect_from_forgery with: :exception

  # Send the access denied pages to root with a nice message
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to issues_path, alert: exception.message
  end

  # Save this page location to session
  after_action :store_location

  # Load Pagy backend
  include Pagy::Backend

  protected

  def configure_permitted_parameters
    # devise_parameter_sanitizer.for(:sign_up).push(:username, :email)
    # devise_parameter_sanitizer.for(:account_update).push(:username, :email)
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def log_event(category, action, label)
    # Log a google analytics event to limit ad spending
    session[:events] ||= Array.new
    session[:events] << {category: category, action: action, label: label}
  end

  def log_fb_event(action, amount)
    # Log an event with Facebook to limit ad spending
    session[:fb_events] ||= Array.new
    session[:fb_events] << {action: action, amount: amount}
  end

  private

  def user_from_ip_whitelist(ip)
    users = User.find_by_whitelist(ip)
    if users and not users.empty?
      return users.first
    else
      return nil
    end
  end

  def auto_signin_ip
    begin
      if !user_signed_in?
        user = user_from_ip_whitelist(request.remote_ip)
        logger.info user
        if !user.nil? and user.subscriber?
          sign_in(:user, user)
          session[:auto_signin] = true
        end
      end
    rescue Exception => e
      logger.info 'Failed auto_signin_ip with error: ' + e.message
      reset_session
    end
    return true
  end

  def current_ability
    guest_pass_key = (params[:guest_pass] or params[:utm_source])
    @current_ability ||= Ability.new(current_user, guest_pass_key)
  end

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  end

  def after_sign_in_path_for(resource)
    # Now overridden in sessions_controller.rb
    session[:previous_url] || root_path
  end

  def retrieve_paypal_express_details(token, options = {})
    autodebit = options[:autodebit] or false
    if autodebit
      ppr = PayPal::Recurring.new(token: token)
      details = ppr.checkout_details
      session[:express_payer_id] = details.payer_id
      session[:express_email] = details.email
      session[:express_first_name] = details.first_name
      session[:express_last_name] = details.last_name
      session[:express_country_code] = details.country
    else
      details = EXPRESS_GATEWAY.details_for(token)
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
    #logger.info "******"
    #logger.info details.params
    #logger.info "******"
  end

end
