class PushRegistrationsController < ApplicationController

  protect_from_forgery :except => [:create]

  def create
    # byebug
    PushRegistration.create!(token: params[:token], device: params[:device])
    render nothing: true
  end

  private

  def push_registration_params
    params.require(:push_registration).permit(:token, :device)
  end

end
