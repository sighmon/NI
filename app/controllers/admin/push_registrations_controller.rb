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
    created_or_updated = PushRegistration.import_from_parse(6)
      
    if not created_or_updated.empty?
      message = "Successfully created or updated: #{created_or_updated.count} registrations."
      logger.info message
      redirect_to admin_push_registrations_path, notice: message
    else
      redirect_to admin_push_registrations_path, flash: { error: "Got a response from Parse, but didn't update or create any registrations. Response: #{response}" }
    end

  end

  # Cancan not working? so we use verify_admin
  before_action :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
