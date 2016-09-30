class PushRegistration < ActiveRecord::Base
  validates :token, uniqueness: true

  def self.import_from_parse(number_of_loops)
    i = 0
    limit = 1000
    created_or_updated_to_return = []

    while i < number_of_loops do
      # Import all of the registrations from parse
      this_created_or_updated = []
      if Rails.env.production?
        parse_app_id = ENV['PARSE_APPLICATION_ID']
        parse_master_key = ENV['PARSE_MASTER_KEY']
      else
        parse_app_id = ENV['PARSE_DEV_APPLICATION_ID']
        parse_master_key = ENV['PARSE_DEV_MASTER_KEY']
      end
      headers = {
        "X-Parse-Application-Id" => parse_app_id,
        "X-Parse-Master-Key" => parse_master_key
      }
      query = {
        "limit": limit,
        "skip": i * limit
      }
      response = HTTParty.get(ENV['PARSE_INSTALLATIONS_API_ENDPOINT'], :headers => headers, :query => query)
      if response and response.success?
        # byebug
        # Find or create the registrations
        response.parsed_response["results"].each do |result|
          reg = PushRegistration.find_or_create_by(token: result["deviceToken"], device: result["deviceType"])
          reg.touch
          this_created_or_updated << reg
        end
        
        if not this_created_or_updated.empty?
          logger.info "Successfully created or updated: #{this_created_or_updated.count} registrations."
        else
          logger.warn "Got a response from Parse, but didn't update or create any registrations. Response: #{response}"
        end
        
      else
        logger.error "Failed to get registrations from Parse. Error: #{response}"
      end
      created_or_updated_to_return += this_created_or_updated
      i += 1
    end

    return created_or_updated_to_return
  end

end
