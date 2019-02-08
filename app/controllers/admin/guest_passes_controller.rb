class Admin::GuestPassesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
    if params[:per_page].present?
      per_page = params[:per_page]
    else
      per_page = Settings.users_pagination
    end
    @guest_passes = Kaminari.paginate_array(GuestPass.order(:use_count).reverse_order.all).page(params[:page]).per(per_page)
  	# @guest_passes = GuestPass.order(:use_count).all.reverse
  end

  # Cancan not working? so we use verify_admin
  before_action :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
