# config/initializers/timeout.rb
# https://devcenter.heroku.com/articles/rails-unicorn
# Suggested timeout set to 5 seconds before the unicorn.rb timeout

Rack::Timeout.timeout = 85  # seconds