# NI::Application.configure do
Rails.application.configure do
# Rails.Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  # config.whiny_nils = true
  config.eager_load = false

  # Rails 4
  config.active_record.migration_error = :page_load
  config.assets.digest = true
  config.assets.raise_runtime_errors = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  # config.action_controller.perform_caching = false

  # Enable server timing
  config.server_timing = true

  # Rails 5
  config.assets.quiet = true
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end
  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Set true to test action cache locally
  # config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  # config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Only use best-standards-support built into browsers
  # config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  # config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Default URL for Devise
  config.action_mailer.default_url_options = { :host => 'localhost:3000', :protocol => 'http' }
  config.action_mailer.asset_host = 'http://localhost:3000'

  # Default URL for helpers in models
  Rails.application.routes.default_url_options = { :host => 'localhost:3000', :protocol => 'http' }

  # Change mail delvery to either :smtp, :sendmail, :file, :test
  # gmail_auth = YAML.load_file("#{Rails.root}/config/environments/gmail_auth.yml")
  # Now using /config/application.yml figaro gem
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    # :domain => "ppp250-143.static.internode.on.net",
    :authentication => :plain,
    :enable_starttls_auto => true,
    :user_name => ENV["GMAIL_USER_NAME"],
    :password => ENV["GMAIL_PASSWORD"]
  }

  # Google Analytics setup
  GA.tracker = ENV["GOOGLE_ANALYTICS_DEVELOPMENT"]

  # Google Tag Manager
  # Set the tag here if you want it to show in development
  GoogleTagManager.gtm_id = "GTM-XXXX"

  # Active Merchant Gateway

  config.after_initialize do

    ActiveMerchant::Billing::Base.mode = :test

    # paypal_auth = YAML.load_file("#{Rails.root}/config/environments/paypal_auth.yml")
    # Now using /config/application.yml figaro gem

    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(
      :login => ENV["PAYPAL_SANDBOX_LOGIN"],
      :password => ENV["PAYPAL_SANDBOX_PASSWORD"],
      :signature => ENV["PAYPAL_SANDBOX_SIGNATURE"]
    )

    PayPal::Recurring.configure do |config|
      config.sandbox = true
      config.username = ENV["PAYPAL_SANDBOX_LOGIN"]
      config.password = ENV["PAYPAL_SANDBOX_PASSWORD"]
      config.signature = ENV["PAYPAL_SANDBOX_SIGNATURE"]
    end

  end

end
