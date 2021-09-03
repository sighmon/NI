# NI::Application.configure do
Rails.application.configure do
# Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Rails 4
  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.js_compressor = :uglifier
  config.log_level = :debug
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false

  # Default URL for Devise
  config.action_mailer.default_url_options = { :host => URI.parse(ENV['NI_APP_HOST']).host, :protocol => 'https' }
  config.action_mailer.asset_host = ENV['NI_APP_HOST']

  # Default URL for helpers in models
  Rails.application.routes.default_url_options = { :host => URI.parse(ENV['NI_APP_HOST']).host, :protocol => 'https' }

  # Change mail delvery to either :smtp, :sendmail, :file, :test
  # gmail_auth = YAML.load_file("#{Rails.root}/config/environments/gmail_auth.yml")
  # Now using /config/application.yml figaro gem
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"

  # Set logger level so Unicorn on Heroku is more verbose
  # http://help.papertrailapp.com/kb/configuration/unicorn
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger.const_get(ENV['LOG_LEVEL'] ? ENV['LOG_LEVEL'].upcase : 'INFO')
  
  # GMAIL SETTINGS
  # config.action_mailer.smtp_settings = {
  #   :address => "smtp.gmail.com",
  #   :port => 587,
  #   # :domain => ENV["GMAIL_USER_NAME"],
  #   :authentication => :plain,
  #   :enable_starttls_auto => true,
  #   :user_name => ENV["GMAIL_USER_NAME"],
  #   :password => ENV["GMAIL_PASSWORD"]
  # }

  # SendGrid settings for Heroku
  config.action_mailer.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :user_name      => 'apikey',
    :password       => ENV['SENDGRID_API_KEY'],
    :domain         => 'heroku.com',
    :enable_starttls_auto => true
  }

  # Google Analytics setup
  GA.tracker = ENV["GOOGLE_ANALYTICS_PRODUCTION"]

  # Google Tag Manager
  GoogleTagManager.gtm_id = ENV["GOOGLE_TAG_MANAGER"]

  # Active Merchant Gateway

  config.after_initialize do

    #ActiveMerchant::Billing::Base.mode = :test

    # paypal_auth = YAML.load_file("#{Rails.root}/config/environments/paypal_auth.yml")
    # Now using /config/application.yml figaro gem

    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(
      :login => ENV["PAYPAL_LOGIN"],
      :password => ENV["PAYPAL_PASSWORD"],
      :signature => ENV["PAYPAL_SIGNATURE"]
    )

    PayPal::Recurring.configure do |config|
      #config.sandbox = true
      config.sandbox = false
      config.username = ENV["PAYPAL_LOGIN"]
      config.password = ENV["PAYPAL_PASSWORD"]
      config.signature = ENV["PAYPAL_SIGNATURE"]
    end

  end

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  # config.serve_static_assets = false
  # Rails 5
  # config.serve_static_files = true # for memcached
  config.public_file_server.enabled = true # for memcached

  # Compress JavaScripts and CSS
  # config.assets.compress = true
  # Setting false to try and fix bootstrap compile issues
  # config.assets.compress = false
  # Rails 5
  # Trying to get assets to compress again 27 June 2014.
  config.assets.compress = true
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Rails 5
  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX
  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Generate digests for assets URLs
  config.assets.digest = true
  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Memcached https://devcenter.heroku.com/articles/rack-cache-memcached-rails31
  # client = Dalli::Client.new((ENV["MEMCACHIER_ROSE_SERVERS"] || "").split(","),
  #                            :username => ENV["MEMCACHIER_ROSE_USERNAME"],
  #                            :password => ENV["MEMCACHIER_ROSE_PASSWORD"],
  #                            :failover => true,
  #                            :socket_timeout => 1.5,
  #                            :socket_failure_delay => 0.2,
  #                            :value_max_bytes => 10485760)
  # config.action_dispatch.rack_cache = {
  #   :metastore    => client,
  #   :entitystore  => client
  # }
  config.cache_store = :mem_cache_store#,
                    # (ENV["MEMCACHIER_ROSE_SERVERS"] || "").split(","),
                    # {:username => ENV["MEMCACHIER_ROSE_USERNAME"],
                    #  :password => ENV["MEMCACHIER_ROSE_PASSWORD"],
                    #  :failover => true,
                    #  :socket_timeout => 1.5,
                    #  :socket_failure_delay => 0.2
                    # }
  config.static_cache_control = "public, max-age=2592000"

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]
  config.log_tags = [ :request_id ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Memcachier is down.. temporarily don't cache..
  # config.cache_store = :null_store

  # Enable serving of images, stylesheets, and JavaScripts from Amazon Cloudfront asset server
  # config.action_controller.asset_host = "https://#{ENV['CLOUDFRONT_SERVER']}.cloudfront.net"

  # Avoid loading external assets for no_tracking pages
  config.action_controller.asset_host = Proc.new { |source, request = nil, *_|
    request && ApplicationHelper.no_tracking(request) ? "#{ENV['NI_APP_HOST']}" : "https://#{ENV['CLOUDFRONT_SERVER']}.cloudfront.net"
  }
  # Enable serving of stylesheets and javascrips from Amazon S3
  # config.action_controller.asset_host = "https://#{ENV['S3_BUCKET']}.s3.amazonaws.com"
  config.assets.enabled = true

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = true

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "ni_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false
end
