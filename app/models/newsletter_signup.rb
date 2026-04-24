class NewsletterSignup
  include ActiveModel::Model

  attr_reader :email

  def email=(value)
    @email = value.to_s.strip
  end

  validates :email,
    presence: true,
    format: {
      with: URI::MailTo::EMAIL_REGEXP,
      message: "must be a valid email address"
    }
end
