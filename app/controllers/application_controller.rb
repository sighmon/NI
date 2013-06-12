class ApplicationController < ActionController::Base

  before_filter :auto_signin_ip

  protect_from_forgery
  # Send the access denied pages to root with a nice message
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to issues_path, :alert => exception.message
  end

  # Save this page location to session
  after_filter :store_location

  private

  def id_from_ip_whitelist(ip)
    get_whitelist.each do |user|
      if ip_in_whitelist_entry?(ip, user[:ip_whitelist])
        return user[:id]
      end
    end
    return nil
  end

  def ip_in_whitelist_entry?(ip, whitelist_entry)
    whitelist_entry.split(",").collect{|s| s.strip}.collect do |entry|
      begin
        if entry.include?("-")
          # IP Range
          from,to = entry.split("-")
          ((IPAddr.new(from)..IPAddr.new(to)) === IPAddr.new(ip))
        else
          # CIDR or plain IP Address
          (IPAddr.new(entry) === IPAddr.new(ip))
        end
      rescue ArgumentError => a
        false
      end
    end.include?(true)
  end

  def get_whitelist
    User.where("parent_id IS NOT NULL").where("ip_whitelist IS NOT NULL").where("ip_whitelist <> ?", "").collect{|u| {id: u.id, ip_whitelist: u.ip_whitelist}}
  end

  def auto_signin_ip
 
    if !user_signed_in?
      id = id_from_ip_whitelist(request.remote_ip)
      logger.info id
      if !id.nil?
        sign_in(:user, User.find(id))
        session[:auto_signin] = true
      end
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
    session[:previous_url] || root_path
  end

  def retrieve_paypal_express_details(token, options = {})
    autodebit = options[:autodebit] or false
    if autodebit
      ppr = PayPal::Recurring.new(:token => token)
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
