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

  # Cancan not working? so we use verify_admin
  before_filter :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
