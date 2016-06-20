class PushRegistrationsController < ApplicationController

  protect_from_forgery :except => [:create]

  def create
    # byebug
    PushRegistration.find_or_create_by(token: params[:token], device: params[:device]).touch
    render nothing: true
  end

  private

  def push_registration_params
    params.require(:push_registration).permit(:token, :device)
  end

end
