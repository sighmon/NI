# config/initializers/bonsai.rb

ENV['ELASTICSEARCH_URL'] = ENV['BONSAI_URL']

# Optional, but recommended: use a single index per application per environment
app_name = Rails.application.class.parent_name.underscore.dasherize
app_env = Rails.env
BONSAI_INDEX_NAME = "#{app_name}-#{app_env}"



# if ENV['BONSAI_INDEX_URL']
#   Tire.configure do
#     url "http://index.bonsai.io/"
#   end
#   BONSAI_INDEX_NAME = ENV['BONSAI_INDEX_URL'][/[^\/]+$/]
# else
#   app_name = Rails.application.class.parent_name.underscore.dasherize
#   BONSAI_INDEX_NAME = "#{app_name}-#{Rails.env}"
# end