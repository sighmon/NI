class UserMailer < ActionMailer::Base
  # set this to subscribe@newint.com.au for production
  default from: ENV["DEVISE_EMAIL_ADDRESS"]

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.subscription_confirmation.subject
  #
  default bcc: ENV["DEVISE_BCC_EMAIL_ADDRESSES"]
  helper :application
  if Rails.env.development?
    default bcc: ENV["DEVISE_BCC_EMAIL_ADDRESSES_DEV"]
  end

  def user_signup_confirmation(user)
    @user = user
    @greeting = "Hello"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    mail(to: user.email, subject: "New Internationalist - Welcome!") do |format|
      format.text
      format.mjml
    end
  end

  def user_signup_confirmation_uk(user)
    @user = user
    @greeting = "Hello"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    mail(to: user.email, subject: "New Internationalist - Welcome!") do |format|
      format.text
      format.mjml
    end
  end

  def subscription_confirmation(subscription)
    @user = subscription.user
    @greeting = "Hi"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    @subscription = subscription
    mail(to: subscription.user.email, subject: "New Internationalist Subscription") do |format|
      format.text
      format.mjml
    end
  end

  def subscription_cancellation(subscription)
    @user = subscription.user
    @greeting = "Hi"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    @subscription = subscription
    mail(to: subscription.user.email, subject: "Cancelled New Internationalist Subscription") do |format|
      format.text
      format.mjml
    end
  end

  def subscription_cancelled_via_paypal(subscription)
    @user = subscription.user
    @greeting = "Hi"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    @subscription = subscription
    mail(to: subscription.user.email, subject: "Cancelled New Internationalist automatic-renewal") do |format|
      format.text
      format.mjml
    end
  end

  def subscription_recurring_payment_outstanding_payment(user)
    @user = user
    @greeting = "Hi"
    mail(to: ENV["DEVISE_EMAIL_ADDRESS"], subject: "recurring_payment_outstanding_payment - New Internationalist Subscription")
  end

  def issue_purchase(purchase)
    @user = purchase.user
    @issue = purchase.issue
    @greeting = "Hi"
    @issues = Issue.where(published: true).last(8).reverse
    @purchase = purchase
    mail(to: purchase.user.email, subject: "New Internationalist Purchase - #{purchase.issue.number} - #{purchase.issue.title}") do |format|
      format.text
      format.mjml
    end
  end

  def free_subscription_confirmation(user, number_of_months)
    @user = user
    @greeting = "Hi"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    @number_of_months = number_of_months
    @subscription = user.subscriptions.last
    mail(to: user.email, subject: "New Internationalist Subscription") do |format|
      format.text
      format.mjml
    end
  end

  def crowdfunding_subscription_confirmation(user,number_of_months)
    @user = user
    @number_of_months = number_of_months
    @greeting = "Hi"
    mail(to: user.email, subject: "Crowdfunding reward - New Internationalist Subscription")
  end

  def media_subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    @subscription = user.subscriptions.last
    mail(to: user.email, subject: "Complimentary New Internationalist Subscription - Media") do |format|
      format.text
      format.mjml
    end
  end

  def make_institutional_confirmation(user)
    @user = user
    @greeting = "Hi"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    mail(to: user.email, subject: "New Internationalist Subscription - Institution confirmation") do |format|
      format.text
      format.mjml
    end
  end

  def admin_email(subject, body_text)
    @user = User.first
    @greeting = "Hello"
    @subject = subject
    @body_text = body_text
    mail(to: ENV["DEVISE_SERVER_ERROR_EMAIL_ADDRESS"], bcc: "", subject: subject) do |format|
      format.mjml
    end
  end

  def uk_server_error(error)
    @error = error
    mail(to: ENV["DEVISE_SERVER_ERROR_EMAIL_ADDRESS"], bcc: "", subject: "digital.newint.com.au UK login SSL server error") do |format|
      format.text
    end
  end

  def subscription_institution_tell_admin(user)
    @user = user
    @greeting = "Hi"
    mail(to: ENV["DEVISE_EMAIL_ADDRESS"], subject: "Possible Institutional Order - New Internationalist Subscription") do |format|
      format.text
    end
  end

end
