class Admin::PushNotificationsController < ApplicationController
  
  # Cancan authorisation
  # load_and_authorize_resource

  def index
    if params[:per_page].present?
      per_page = params[:per_page]
    else
      per_page = Settings.users_pagination
    end

    @pn_total = Rpush::Notification.count
    @pn_undelivered = Rpush::Notification.where(delivered: false).count

    @push_notifications = Kaminari.paginate_array(Rpush::Notification.order(:updated_at).reverse_order.all).page(params[:page]).per(per_page)
  end

  # def destroy
  #   @push_notification = Rpush::Notification.find(params[:id])

  #   respond_to do |format|
  #     if @push_notification.destroy
  #       format.html { redirect_to admin_push_notifications_path, notice: 'This push notification has been destroyed.' }
  #       format.json { head :no_content }
  #     else
  #       format.html { redirect_to admin_push_notifications_path, notice: "Sorry, couldn't destroy this push notification. Error: #{@push_notification.errors}" }
  #       format.json { render json: @push_notification.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # Cancan not working? so we use verify_admin
  before_filter :verify_admin
  private
  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
