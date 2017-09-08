class PushRegistrationsController < ApplicationController

  protect_from_forgery :except => [:create]

  def create
    # byebug
    PushRegistration.find_or_create_by(token: params[:token], device: params[:device]).touch
    render json: {success: true}
  end

  def destroy
    @push_registration = PushRegistration.find(params[:id])

    respond_to do |format|
      if @push_registration.destroy
        format.html { redirect_to admin_push_registrations_path, notice: 'This push registration has been deleted.' }
        format.json { head :no_content }
      else
        format.html { redirect_to admin_push_registrations_path, notice: "Sorry, couldn't destroy this push registration. Error: #{@push_registration.errors}" }
        format.json { render json: @push_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def push_registration_params
    params.require(:push_registration).permit(:token, :device)
  end

end
