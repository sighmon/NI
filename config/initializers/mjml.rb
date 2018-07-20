# NOTE: not used anymore, this was for the old mjml-ruby gem
# Now using the mjml-rails gem

# class Mjml::Rails::ERBContext
#   include ActionView::Helpers
#   include ::Rails.application.routes.url_helpers
#   default_url_options[:host] = Rails.env.production? ? ENV['NI_APP_HOST'] : 'localhost:3000'
#   # TODO: Fix setting this correctly. Use Cloudfront.
#   # asset_host = Rails.env.production? ? ENV['NI_APP_HOST'] : 'localhost:3000'
# end

Mjml.setup do |config|
  # config.template_language = :erb # :erb (default), :slim, :haml, or any other you are using
  # Default is `false` (errors suppressed), set to `true` to enable error raising
  config.raise_render_exception = true
  # config.mjml_binary_version_supported = "4.0."
end
