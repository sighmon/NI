class Admin::PushNotificationsController < ApplicationController
  
  # Cancan authorisation
  # load_and_authorize_resource

  # verify_admin
  before_filter :verify_admin

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

  def destroy
    @push_notification = Rpush::Notification.find(params[:id])

    respond_to do |format|
      if @push_notification.destroy
        format.html { redirect_to admin_push_notifications_path, notice: 'This push notification has been destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to admin_push_notifications_path, notice: "Sorry, couldn't destroy this push notification. Error: #{@push_notification.errors}" }
        format.json { render json: @push_notification.errors, status: :unprocessable_entity }
      end
    end
  end

  def send_notifications
    # Another paranoid check
    if current_user and current_user.admin?
      # Send the setup push notifications
      rpush_response = Rpush.push

      # TODO: Check for Rpush.apns_feedback and store somewhere??? Send email to admin? 

      if rpush_response and rpush_response.empty?
        # Success!
        redirect_to admin_push_notifications_path, notice: "Push notifications sent without error!"
      else
        # FAIL! server error.
        redirect_to admin_push_notifications_path, flash: { error: "Failed to send push notifications. Error: #{rpush_response}" }
      end
    else
      redirect_to root_url
    end
  end

  private

  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
