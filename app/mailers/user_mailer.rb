class UserMailer < ActionMailer::Base
  # set this to subscribe@newint.com.au for production
  default :from => ENV["DEVISE_EMAIL_ADDRESS"]

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.subscription_confirmation.subject
  #
  default :bcc => ENV["DEVISE_BCC_EMAIL_ADDRESSES"]
  if Rails.env.development?
    default :bcc => ENV["DEVISE_BCC_EMAIL_ADDRESSES_DEV"]
  end

  def user_signup_confirmation(user)
    @user = user
    @greeting = "Hello"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    mail(:to => user.email, :subject => "New Internationalist - Welcome!")
  end

  def user_signup_confirmation_uk(user)
    @user = user
    @greeting = "Hello"
    @issue = Issue.latest
    @issues = Issue.where(published: true).last(8).reverse
    mail(:to => user.email, :subject => "New Internationalist - Welcome!")
  end

  def subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :subject => "New Internationalist Digital Subscription")
  end

  def subscription_cancellation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :subject => "Cancelled New Internationalist Digital Subscription")
  end

  def subscription_cancelled_via_paypal(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :subject => "Cancelled New Internationalist Digital Subscription")
  end

  def subscription_recurring_payment_outstanding_payment(user)
    @user = user
    @greeting = "Hi"
    mail(:to => ENV["DEVISE_EMAIL_ADDRESS"], :subject => "recurring_payment_outstanding_payment - New Internationalist Digital Subscription")
  end

  def issue_purchase(user, issue)
    @user = user
    @issue = issue
    @greeting = "Hi"
    mail(:to => user.email, :subject => "New Internationalist Purchase - #{issue.number} - #{issue.title}")
  end

  def free_subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :subject => "Complimentary New Internationalist Digital Subscription")
  end

  def crowdfunding_subscription_confirmation(user,number_of_months)
    @user = user
    @number_of_months = number_of_months
    @greeting = "Hi"
    mail(:to => user.email, :subject => "Crowdfunding reward - New Internationalist Digital Subscription")
  end

  def media_subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :subject => "Complimentary New Internationalist Digital Subscription - Media")
  end

  def make_institutional_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :subject => "New Internationalist Digital Subscription - Institution confirmation")
  end

  def uk_server_error(error)
    @error = error
    mail(:to => ENV["DEVISE_SERVER_ERROR_EMAIL_ADDRESS"], :bcc => "", :subject => "digital.newint.com.au UK login SSL server error")
  end

  def subscription_institution_tell_admin(user)
    @user = user
    @greeting = "Hi"
    mail(:to => ENV["DEVISE_EMAIL_ADDRESS"], :subject => "Possible Institutional Order - New Internationalist Digital Subscription")
  end

end
