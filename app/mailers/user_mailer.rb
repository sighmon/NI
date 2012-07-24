class UserMailer < ActionMailer::Base
  default from: "subscribe@newint.com.au"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.subscription_confirmation.subject
  #
  def subscription_confirmation(user)
    @user = user
    @greeting = "Hi there"
    mail to: user.email, subject: "New Internationalist Digital Subscription"
  end
end
