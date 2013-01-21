class Admin::GuestPassesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
  	@guest_passes = GuestPass.all(:order => "use_count").reverse
  end

  # Cancan not working? so we use verify_admin
  before_filter :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
