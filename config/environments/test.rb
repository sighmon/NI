# NI::Application.configure do
Rails.application.configure do
# Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Rails 4
  config.eager_load = false

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true
  config.serve_static_files = true
  config.active_support.test_order = :random

  # Configure static asset server for tests with Cache-Control for performance
  # config.serve_static_assets = true
  # Rails 5
  # config.static_cache_control = "public, max-age=3600"
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Rails 8
  config.cache_store = :null_store
  config.active_storage.service = :test
  config.action_controller.raise_on_missing_callback_actions = true
  # turn caching ON for specs that rely on it
  config.action_controller.perform_caching = true
  # use an in-process store that survives for the whole example
  config.cache_store = :memory_store, { size: 64.megabytes }

  # Raise exceptions instead of rendering exception templates
  # config.action_dispatch.show_exceptions = false
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Raise exception on mass assignment protection for Active Record models
  # config.active_record.mass_assignment_sanitizer = :strict

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Default URL for Devise
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Raise an exception on unpermitted params
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Raise exceptions for disallowed deprecations.
  # config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  # config.active_support.disallowed_deprecation_warnings = []

end
