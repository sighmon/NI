class Admin::PushRegistrationsController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
    if params[:per_page].present?
      per_page = params[:per_page]
    else
      per_page = Settings.users_pagination
    end
    # @push_registrations = PushRegistration.order(:updated_at).reverse_order.all
    @push_registrations = Kaminari.paginate_array(PushRegistration.order(:updated_at).reverse_order.all).page(params[:page]).per(per_page)
  end

  def import
    # Import push registrations from parse
    if Rails.env.production?
      parse_app_id = ENV['PARSE_APPLICATION_ID']
      parse_master_key = ENV['PARSE_MASTER_KEY']
    else
      parse_app_id = ENV['PARSE_DEV_APPLICATION_ID']
      parse_master_key = ENV['PARSE_DEV_MASTER_KEY']
    end
    headers = {
      "X-Parse-Application-Id" => parse_app_id,
      "X-Parse-Master-Key" => parse_master_key
    }
    response = HTTParty.get(ENV['PARSE_INSTALLATIONS_API_ENDPOINT'], :headers => headers)
    if response and response.success?
      # Find or create the registrations
      created_or_updated = []

      response.parsed_response["results"].each do |result|
        reg = PushRegistration.find_or_create_by(token: result["deviceToken"], device: result["deviceType"])
        reg.touch
        created_or_updated << reg
      end
      
      if not created_or_updated.empty?
        redirect_to admin_push_registrations_path, notice: "Successfully created or updated: #{created_or_updated.count} registrations."
      else
        redirect_to admin_push_registrations_path, flash: { error: "Got a response from Parse, but didn't update or create any registrations. Response: #{response}" }
      end
      
    else
      redirect_to admin_push_registrations_path, flash: { error: "Failed to get registrations from Parse. Error: #{response}" }
    end
  end

  # Cancan not working? so we use verify_admin
  before_filter :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
