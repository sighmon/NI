class ActiveSupport::TimeWithZone
  def as_json(options = {})
  	# NOTE: Added this monkey patch to remove the sub-second accuracy from JSON feeds
  	# SEE: https://github.com/rails/rails/pull/9128
    strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end