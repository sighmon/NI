module Devise
  module Models
    module RemoteAuthenticatable
      extend ActiveSupport::Concern
 
      # module ClassMethods
      #   ####################################
      #   # Overriden methods from Devise::Models::Authenticatable
      #   ####################################
 
      #   #
      #   # This method is called from:
      #   # Warden::SessionSerializer in devise
      #   #
      #   # It takes as many params as elements had the array
      #   # returned in serialize_into_session
      #   #
      #   # Recreates a resource from session data
      #   #
      #   def serialize_from_session(id)
      #     logger.info "XXXXXX SERIALIZE_FROM_SESSION"
      #     logger.info id.to_json
      #     resource = self.new
      #     resource.id = id
      #     resource.email = email
      #     resource.username = username
      #     # resource.uk_id = uk_id
      #     # resource.uk_expiry = uk_expiry
      #     resource
      #   end
 
      #   #
      #   # Here you have to return and array with the data of your resource
      #   # that you want to serialize into the session
      #   #
      #   # You might want to include some authentication data
      #   #
      #   def serialize_into_session(record)
      #     logger.info "XXXXXX SERIALIZE_INTO_SESSION"
      #     if record
      #       logger.info "Record: #{record.to_json}"
      #       [record.id, record.email, record.username]
      #       # [record.uk_id]
      #       # [record.uk_expiry]
      #     end
      #   end
 
      # end
    end
  end
end