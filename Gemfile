source 'https://rubygems.org'

ruby '2.7.4'

gem 'rails', '6.1.4.4'

gem 'sprockets'

#### Rails 4 upgrade
# gem 'protected_attributes'
gem 'rails-observers', git: 'https://github.com/rails/rails-observers.git'
gem 'actionpack-page_caching', git: 'https://github.com/rails/actionpack-page_caching.git'
gem 'actionpack-action_caching', git: 'https://github.com/rails/actionpack-action_caching.git'
gem 'activerecord-deprecated_finders'
gem 'activerecord-session_store'

# Rails 5
# gem 'record_tag_helper'

#### For heroku to serve static assets
gem 'rails_serve_static_assets'

# So we can serve static assets via S3 and CloudFront CDN
# gem 'asset_sync'

# Heroku platform-api
gem 'platform-api'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'

gem 'pg'

# Delayed Job for background CSV generation
# https://devcenter.heroku.com/articles/delayed-job
# To run jobs locally $ rake jobs:work
gem 'delayed_job_active_record'

# User authentication via Devise https://github.com/plataformatec/devise
gem 'devise'

# reCAPTCHA to avoid spam sign-ups
gem 'recaptcha', require: 'recaptcha/rails'

# User role management via Cancan https://github.com/ryanb/cancan
gem 'cancancan'

# Form rendering via Formtastic https://github.com/justinfrench/formtastic
gem 'formtastic'

# Active Merchant for purchasing https://github.com/Shopify/active_merchant
gem 'activemerchant', :require => 'active_merchant'

# PayPal recurring billing https://github.com/fnando/paypal-recurring
gem 'paypal-recurring'

# Rails settings file for prices & general settings
# Specifying 1.x as version 2 works very differently
# gem 'ledermann-rails-settings', :require => 'rails-settings'

# Now using a fork for Rails 4
gem 'rails-settings-cached', '0.4.1'

# Environment settings via Figaro https://github.com/laserlemon/figaro
gem 'figaro'

# SOAP client via Savon http://railscasts.com/episodes/290-soap-with-savon
gem 'savon', '~>1.2.0'

# Different HTTPI adapter for Savon to solve missing cookie problem from Bricolage
gem 'curb'

# Using meta-tags for head meta https://github.com/kpumuk/meta-tags
gem 'meta-tags', :require => 'meta_tags'

# BugHerd gem for bug reporting https://github.com/BugHerd/bugherd-ruby
# gem 'bugherd'

# Google Analytics https://github.com/bgarret/google-analytics-rails
gem 'google-analytics-rails'

# Google Tag Manager https://github.com/rcs/google-tag-manager-rails
gem 'google-tag-manager-rails'

# Google Sitemap generator https://github.com/kjvarga/sitemap_generator
gem 'sitemap_generator'

# Heroku gem
# gem 'heroku'

# Unicorn gem for adding Concurrency to Rails Apps on heroku
gem 'unicorn'

# New Relic for server information https://devcenter.heroku.com/articles/newrelic
gem 'newrelic_rpm'#, '6.12.0.367'

# rubyzip for zipping up the issues https://github.com/rubyzip/rubyzip
# gem 'rubyzip'

# trying zipruby instead to see if it has less memory problems on heroku
# https://rubygems.org/gems/zipruby
gem 'zipruby'

# Rack Cache and memcached https://devcenter.heroku.com/articles/rack-cache-memcached-rails31
# gem 'rack-cache'
gem 'dalli'
# gem 'kgio'
gem 'memcachier'

# Rack deflate https://github.com/romanbsd/heroku-deflater
# gem 'heroku-deflater', :group => :production

# Trying another gzip deflater https://github.com/mattolson/heroku_rails_deflate
# gem 'heroku_rails_deflate'

# Get rid of heroku plugin warnings
gem 'rails_12factor', :group => :production

# HTTParty for talking to the UK server
gem 'httparty'

# To talk to the Google Play API
gem 'google-api-client', '0.28.7'

# mjml responsive email framework https://mjml.io
# https://github.com/angelodlfrtr/mjml-ruby
# gem 'mjml', git: 'https://github.com/angelodlfrtr/mjml-ruby.git'

gem 'mjml-rails'#, '2.4.3'#, git: 'https://github.com/sighmon/mjml-rails.git', require: 'mjml'
# gem 'mjml-rails', path: '../mjml-rails/'#, require: 'mjml'

# RPush for push notifications migrating away from Parse
gem 'rpush'
# Temporary fix for rpush:
# https://github.com/rpush/rpush/issues/306
gem 'net-http-persistent'#, '~> 2.9.4'

# zipline for streaming S3 images to the zip
# gem 'zipline'

# Instagram feed https://github.com/facebookarchive/instagram-ruby-gem
# gem 'instagram'

# Location for sending subscriptions to the correct offices
# https://github.com/alexreisner/geocoder
# gem 'geocoder'

# For header security https://github.com/twitter/secureheaders
gem 'secure_headers'

# For development
group :development do
  # gem 'taps', :require => false
  gem 'better_errors'
  gem 'binding_of_caller'
  # gem 'sqlite3'
  # Profiling
  gem 'rack-mini-profiler'
  gem 'flamegraph'
  gem 'stackprof'
  # Run brakeman to check for security problems in your code.
  gem 'brakeman', :require => false
  # Run bundle-audit to check for Ruby/Rails vulnerabilities
  gem 'bundler-audit'
  gem 'ruby-prof'
  gem 'thin'
end

# Cucumber and Rspec install for testing
group :test, :development do
  gem 'rspec-rails'#, '~> 3.0'
  gem 'factory_bot_rails'
  gem 'show_me_the_cookies'
  gem 'byebug'
end

group :test do
  # i don't THINK we use cucumber anymore
  #gem 'cucumber-rails', :require => false
  #gem 'capybara'
  #gem 'capybara-webkit'
  gem 'database_cleaner'
  gem 'simplecov', :require => false
  gem 'timecop'
  gem 'rubocop-rspec'
  # NOTE: to update rspec and fix the bundle update, comment out Guard gem below
  gem 'guard-rspec'#, '1.2.1'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-legacy_formatters'
  # Guard automatic test notifications
  # Heroku doesn't like RUBY_PLATFORM, so not using these for now.
  gem 'rb-inotify', :require => false#, '~> 0.8.8', :require => false # if RUBY_PLATFORM =~ /linux/i
  gem 'rb-fsevent', :require => false#, '~> 0.9.1', :require => false # if RUBY_PLATFORM =~ /darwin/i
  gem 'growl', :require => false # if RUBY_PLATFORM =~ /darwin/i
  # Rails 5
  gem 'rails-controller-testing'
end

# gem 'twitter-bootstrap-rails'#, '2.1.6'
# gem 'bootstrap-sass'
gem 'bootstrap', '~> 4'#, '>= 4.3.1'
# gem 'less-rails'
gem 'libv8'#, '~> 3.11.8'
gem 'mini_racer', '~> 0.4.0'
gem 'font-awesome-rails'

# Gems used only for assets and not required
# in production environments by default.
# group :assets do
gem 'sassc'
gem 'coffee-rails'#, '~> 3.2.1'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', :platform => :ruby

gem 'uglifier', '>= 1.0.3'
# Twitter Bootstrap for styling https://github.com/seyhunak/twitter-bootstrap-rails
# http://twitter.github.com/bootstrap/
# gem 'twitter-bootstrap-rails'#, '2.1.6'
gem 'jquery-fileupload-rails'

# URI.js for highligher URL mutation https://github.com/rweng/uri-js-rails
gem 'uri-js-rails'
# end

gem 'jquery-rails'

# Adding jquery-ui-rails because of an update that removed ui
# http://stackoverflow.com/questions/17830313/couldnt-find-file-jquery-ui
gem 'jquery-ui-rails'

# For forms to work with Bootstrap for twitter
# https://github.com/plataformatec/simple_form
gem 'simple_form'
gem 'country_select'
gem 'country_state_select'

# RMagick for image editing
gem 'rmagick', :require => false
gem 'mini_magick'

# CarrierWave for image uploading
# https://github.com/jnicklas/carrierwave
gem 'carrierwave'

# Using Fog for Amazon S3 image storage so it works with Heroku
# https://github.com/jnicklas/carrierwave (see S3 section)
gem 'fog'#, '~> 1.3.1'

# RetinaImageTag for retina display support
# https://github.com/ffaerber/retina_image_tag
gem 'retina_image_tag', :git => 'https://github.com/sighmon/retina_image_tag.git'

# Highlighter.js for highlighting text
gem 'highlighter-js', :git => 'https://github.com/sighmon/highlighter.js.git'

# Kaminari for pagination http://railscasts.com/episodes/254-pagination-with-kaminari
# Fixed broken layout http://stackoverflow.com/questions/12282240/kaminari-pagination-layout-is-broken
gem 'kaminari'#, '~> 0.13.0'
gem 'kaminari-bootstrap'#, '0.1.2' # '~> 0.1.2' # 0.1.3 breaks locally for some reason.

# Pagy for faster pagination
gem 'pagy'

# Elasticsearch for archive and article search
# Note: pinned 24/5/2019 because of SSL error on heroku
# ActionView::Template::Error (SSL_connect returned=1 errno=0 state=SSLv3/TLS write client hello: wrong version number):
gem 'elasticsearch-model'
gem 'elasticsearch-rails'

# Acts as list for sortable lists
# http://railscasts.com/episodes/147-sortable-lists-revised?view=asciicast
gem 'acts_as_list'

# CSV exporting gem
# https://github.com/crafterm/comma
# gem 'comma', '~> 3.0'
gem 'comma',  :git => "https://github.com/crafterm/comma.git"

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
