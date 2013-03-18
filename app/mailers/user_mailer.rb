class UserMailer < ActionMailer::Base
  # set this to subscribe@newint.com.au for production
  default :from => "subscribe@newint.com.au"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.subscription_confirmation.subject
  #

  def user_signup_confirmation(user)
    @user = user
    @greeting = "Hello"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "New Internationalist - Welcome!")
  end

  def subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "New Internationalist Digital Subscription")
  end

  def subscription_cancellation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "Cancelled New Internationalist Digital Subscription")
  end

  def subscription_cancelled_via_paypal(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "Cancelled New Internationalist Digital Subscription")
  end

  def issue_purchase(user, issue)
    @user = user
    @issue = issue
    @greeting = "Hi"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "New Internationalist Purchase - #{issue.number} - #{issue.title}")
  end

  def free_subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "Complimentary New Internationalist Digital Subscription")
  end

  def media_subscription_confirmation(user)
    @user = user
    @greeting = "Hi"
    mail(:to => user.email, :bcc => "design@newint.com.au, marketing@newint.com.au", :subject => "Complimentary New Internationalist Digital Subscription - Media")
  end

end
