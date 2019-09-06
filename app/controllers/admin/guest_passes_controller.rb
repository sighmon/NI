class Admin::GuestPassesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
    if params[:per_page].present?
      per_page = params[:per_page]
    else
      per_page = Settings.users_pagination
    end
    @pagy, @guest_passes = pagy(GuestPass.order(:use_count).reverse_order.all)
  end

  # Cancan not working? so we use verify_admin
  before_action :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
