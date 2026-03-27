class NewsletterSignup
  include ActiveModel::Model

  attr_accessor :email

  validates :email,
    presence: true,
    format: {
      with: URI::MailTo::EMAIL_REGEXP,
      message: "must be a valid email address"
    }
end
