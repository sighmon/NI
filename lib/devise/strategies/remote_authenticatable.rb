require 'httparty'
require 'json'

module Devise
  module Strategies
    class RemoteAuthenticatable < Authenticatable
      #
      # For an example check : https://github.com/plataformatec/devise/blob/master/lib/devise/strategies/database_authenticatable.rb
      #
      # Method called by warden to authenticate a resource.
      #
      def authenticate!
        #
        # authentication_hash doesn't include the password
        #
        auth_params = authentication_hash
        auth_params[:password] = password

        #
        # mapping.to is a wrapper over the resource model
        #
        resource = remote_authentication_uk_user(auth_params)
        Rails.logger.debug "Resource: #{resource.to_json}"

        return fail! unless resource

        # remote_authentication method is defined in Devise::Models::RemoteAuthenticatable
        #
        # validate is a method defined in Devise::Strategies::Authenticatable. It takes
        #a block which must return a boolean value.
        #
        # If the block returns true the resource will be loged in
        # If the block returns false the authentication will fail!
        #
        if validate_resource(resource)
          success!(resource)
        else
          fail!
        end
      end

      private

      def remote_authentication_uk_user(authentication_hash)
        # Returns a hash with the result

        api_endpoint = ENV["NI_UK_SUBSCRIBER_API"] + authentication_hash[:login] + "/" + authentication_hash[:password] + "/" + ENV["NI_UK_SUBSCRIBER_API_SECRET"]
        response = HTTParty.get(
          api_endpoint, 
          headers: {}
        )
        
        if response.code == 200
          # Success!
          body = JSON.parse(response.body)
          Rails.logger.debug "SUCCESS! Found UK user: #{body["data"]["lname"]}, expiry: #{body["data"]["expiry"]}"
          return body
        # elsif response.code == 404
        #   body = JSON.parse(response.body)
        #   Rails.logger.debug "NOT FOUND! Can't find UK user with ID: #{authentication_hash[:login]}, lname: #{authentication_hash[:password]}"
        #   return body
        else
          Rails.logger.debug "FAIL! UK Response code: #{response.code}"
          return nil
        end
      end

      def build_user_from_resource(resource)
        if resource
          {:email => resource["data"]["email"], :id => resource["data"]["id"], :username => resource["data"]["fname"] + resource["data"]["lname"], :uk_expiry => resource["data"]["expiry"]}
        end
      end

      def validate_resource(resource)
        resource["status"] == "success"
      end

    end
  end
end

# Warden::Strategies.add(:remote_authenticatable, Devise::Strategies::RemoteAuthenticatable)