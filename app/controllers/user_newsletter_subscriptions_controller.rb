class UserNewsletterSubscriptionsController < ApplicationController
  before_action :require_current_user
  before_action :set_user

  def show
    render_result(newsletter_service.status)
  end

  def create
    render_result(newsletter_service.subscribe)
  end

  def destroy
    render_result(newsletter_service.unsubscribe)
  end

  private

  def require_current_user
    head :unauthorized unless current_user
  end

  def set_user
    @user = User.find(params[:user_id])
    head :forbidden unless current_user == @user && can?(:manage, @user)
  end

  def newsletter_service
    @newsletter_service ||= WhatCounts::NewsletterSubscription.new(email: @user.email)
  end

  def render_result(result)
    status = result.success? ? :ok : :bad_gateway

    render json: {
      subscribed: result.subscribed,
      message: result.message
    }, status: status
  end
end
