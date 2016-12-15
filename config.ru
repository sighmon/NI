# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
# Print logs for THIN server
# if Rails.env.development?
#   console = ActiveSupport::Logger.new($stdout)
#   console.formatter = Rails.logger.formatter
#   console.level = Rails.logger.level

#   Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
# end
run NI::Application
