class Mjml::Rails::ERBContext
  include ActionView::Helpers
  include ::Rails.application.routes.url_helpers
  default_url_options[:host] = ENV['NI_APP_HOST']
end

