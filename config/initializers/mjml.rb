class Mjml::Rails::ERBContext
  include ActionView::Helpers
  include ::Rails.application.routes.url_helpers
  default_url_options[:host] = Rails.env.production? ? ENV['NI_APP_HOST'] : 'localhost:3000'
  asset_host = Rails.env.production? ? ENV['NI_APP_HOST'] : 'localhost:3000'
end

