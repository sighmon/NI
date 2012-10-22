source 'https://rubygems.org'

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'

# Postgresql to fix error 17th Sept 2012
# http://stackoverflow.com/questions/7087385/pg-gem-trace-bpt-trap-5-error-on-mac-os-x-lion
gem 'pg'

# User authentication via Devise https://github.com/plataformatec/devise
gem 'devise'

# User role management via Cancan https://github.com/ryanb/cancan
gem 'cancan'

# Form rendering via Formtastic https://github.com/justinfrench/formtastic
gem 'formtastic'

# Active Merchant for purchasing https://github.com/Shopify/active_merchant
gem 'activemerchant', :require => 'active_merchant'

# PayPal recurring billing https://github.com/fnando/paypal-recurring
gem 'paypal-recurring'

# Rails settings file for prices & general settings
gem 'ledermann-rails-settings', :require => 'rails-settings'

# Environment settings via Figaro https://github.com/laserlemon/figaro
gem 'figaro'

# Heroku gem
# gem 'heroku'

# For development
group :development do
  gem 'taps', :require => false
  # gem 'sqlite3'
end

# Cucumber and Rspec install for testing
group :test, :development do
  gem 'rspec-rails'
end

group :test do
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'simplecov', :require => false
  gem 'factory_girl'

end

gem 'twitter-bootstrap-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
  # Twitter Bootstrap for styling https://github.com/seyhunak/twitter-bootstrap-rails
  # http://twitter.github.com/bootstrap/
  gem 'twitter-bootstrap-rails'
end

gem 'jquery-rails'

# For forms to work with Bootstrap for twitter
# https://github.com/plataformatec/simple_form
gem 'simple_form'

# RMagick for image editing
gem 'rmagick', :require => false

# CarrierWave for image uploading
# https://github.com/jnicklas/carrierwave
gem 'carrierwave'

# Using Fog for Amazon S3 image storage so it works with Heroku
# https://github.com/jnicklas/carrierwave (see S3 section)
gem 'fog', '~> 1.3.1'

# RetinaImageTag for retina display support
# https://github.com/ffaerber/retina_image_tag
gem 'retina_image_tag'

# Kaminari for pagination http://railscasts.com/episodes/254-pagination-with-kaminari
# Fixed broken layout http://stackoverflow.com/questions/12282240/kaminari-pagination-layout-is-broken
gem 'kaminari', '~> 0.13.0'
gem 'kaminari-bootstrap', '~> 0.1.2'

# Tire for elasticsearch
# http://railscasts.com/episodes/306-elasticsearch-part-1
gem 'tire'

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
