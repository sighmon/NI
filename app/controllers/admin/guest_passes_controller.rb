class Admin::GuestPassesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
  	@guest_passes = GuestPass.all
  end
end
