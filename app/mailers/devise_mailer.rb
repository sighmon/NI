class DeviseMailer < Devise::Mailer
  def reset_password_instructions(record, token, opts={})
    # mail = super
    # Custom logic to send the email with MJML
    @token = token
    @resource = record
    mail(
      :template_path => 'devise/mailer',
      :from => ENV["DEVISE_EMAIL_ADDRESS"], 
      :to => record.email, 
      :subject => "New Internationalist - Reset password"
    ) do |format|
      format.mjml
      format.text
    end
  end
end