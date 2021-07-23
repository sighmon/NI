# require File.expand_path('../boot', __FILE__)

# Rails 5
require_relative 'boot'

require 'rails/all'

# For instrumentation stats
#require 'elasticsearch/rails/instrumentation'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module NI
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths << "#{Rails.root}/lib"
    config.eager_load_paths << "#{Rails.root}/lib"

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Adelaide'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # To supress deprecation warning for Rails 3.2.14 and above
    config.i18n.enforce_available_locales = true

    # Rails 4 addition
    # Removed for Rails 5
    # config.active_record.raise_in_transactional_callbacks = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    # config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    #### Removed for Rails 4
    # config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Recommended from Devise for Heroku use
    # On config/application.rb forcing your application to not access the DB
    # or load models when precompiling your assets.
    config.assets.initialize_on_precompile = false

    # add app/assets/fonts to the asset path
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    # add app/assets/html to the asset path
    config.assets.paths << "#{Rails.root}/app/assets/html"

    # Memcached https://devcenter.heroku.com/articles/rack-cache-memcached-rails31
    config.cache_store = :dalli_store

    config.generators do |g|
      g.fixture_replacement :factory_girl
    end

    config.to_prepare do
      DeviseController.respond_to :html, :json
      Devise::SessionsController.skip_before_action :auto_signin_ip
    end
  end
end
