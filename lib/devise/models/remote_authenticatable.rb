require 'httparty'
require 'json'

module Devise
  module Models
    module RemoteAuthenticatable
      extend ActiveSupport::Concern
 
      #
      # Here you do the request to the external webservice
      #
      # If the authentication is successful you should return
      # a resource instance
      #
      # If the authentication fails you should return false
      #
      def remote_authentication(authentication_hash)
        # Your logic to authenticate with the external webservice

        api_endpoint = ENV["NI_UK_SUBSCRIBER_API"] + authentication_hash[:login] + "/" + authentication_hash[:password] + "/" + ENV["NI_UK_SUBSCRIBER_API_SECRET"]
        response = HTTParty.get(
          api_endpoint, 
          headers: {}
        )
        
        if response.code == 200
          # Success!
          body = JSON.parse(response.body)
          logger.info "SUCCESS! Found UK user: #{body["data"]["lname"]}, expiry: #{body["data"]["expiry"]}"
          # resource = self.new
          session[:current_user_id] = body["data"]["id"].to_i
          session[:email] = body["data"]["email"]
          session[:username] = body["data"]["fname"] + body["data"]["lname"]
          session[:uk_expiry] = body["data"]["expiry"]
          # logger.info resource
          return true
        else
          return false
        end
      end
 
      module ClassMethods
        ####################################
        # Overriden methods from Devise::Models::Authenticatable
        ####################################
 
        #
        # This method is called from:
        # Warden::SessionSerializer in devise
        #
        # It takes as many params as elements had the array
        # returned in serialize_into_session
        #
        # Recreates a resource from session data
        #
        def serialize_from_session(id)
          logger.info "XXXXXX SERIALIZE_FROM_SESSION"
          logger.info id
          resource = self.new
          resource.id = id
          resource
        end
 
        #
        # Here you have to return and array with the data of your resource
        # that you want to serialize into the session
        #
        # You might want to include some authentication data
        #
        def serialize_into_session(record)
          logger.info "XXXXXX SERIALIZE_INTO_SESSION"
          [record.id]
          [record.email]
          [record.username]
          # [record.uk_expiry]
        end
 
      end
    end
  end
end