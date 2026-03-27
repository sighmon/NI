class NewslettersController < ApplicationController

  def show
    @newsletter_signup = NewsletterSignup.new
  end

  def create
    @newsletter_signup = NewsletterSignup.new(newsletter_signup_params)

    if @newsletter_signup.invalid?
      render :show, status: :unprocessable_entity
      return
    end

    result = WhatCounts::NewsletterSubscription.new(email: @newsletter_signup.email).call

    if result.success?
      redirect_to newsletter_path, notice: result.message
    else
      flash.now[:alert] = result.message
      render :show, status: :bad_gateway
    end
  end

  private

  def newsletter_signup_params
    params.fetch(:newsletter_signup, {}).permit(:email)
  end
end
