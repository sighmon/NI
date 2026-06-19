class Admin::PushNotificationsController < ApplicationController
  
  # Cancan authorisation
  # load_and_authorize_resource

  # verify_admin
  before_action :verify_admin

  def index
    if params[:per_page].present?
      per_page = params[:per_page]
    else
      per_page = Settings.users_pagination
    end

    @pn_total = Rpush::Notification.count
    @pn_undelivered = Rpush::Notification.where(delivered: false).count

    @pagy, @push_notifications = pagy(Rpush::Notification.order(:updated_at).reverse_order.all)
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

  def run_delayed_jobs
    ApplicationHelper.start_delayed_jobs
    redirect_to admin_push_notifications_path, notice: "Delayed jobs running..."
  end

  def send_notifications
    # Another paranoid check
    if current_user and current_user.admin?
      result = ApplicationHelper.rpush_send_notifications

      if result[:attempted].zero?
        redirect_to admin_push_notifications_path, notice: "No push notifications were ready to send."
      elsif result[:failed].zero? && result[:pending].zero?
        redirect_to admin_push_notifications_path,
                    notice: "#{result[:delivered]} push notifications delivered."
      else
        redirect_to admin_push_notifications_path,
                    flash: {
                      error: "Push delivery incomplete: #{result[:delivered]} delivered, " \
                             "#{result[:failed]} failed, #{result[:pending]} pending."
                    }
      end
    else
      redirect_to root_url
    end
  rescue StandardError => error
    logger.error "Failed to send push notifications: #{error.class}: #{error.message}"
    redirect_to admin_push_notifications_path, flash: { error: "Failed to send push notifications: #{error.message}" }
  end

  private

  def verify_admin
    redirect_to root_url unless (current_user and current_user.admin?)
  end

end
