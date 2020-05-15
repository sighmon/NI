require 'httparty'
require 'json'

module Devise
  module Strategies
    class RemoteAuthenticatable < Authenticatable
      #
      # Method called by warden to authenticate a resource.
      #
      def authenticate!
        #
        # authentication_hash doesn't include the password
        #
        auth_params = authentication_hash
        auth_params[:password] = password

        # Check with the UK Server for the user
        uk_user_details = remote_authentication_uk_user(auth_params)

        # Fail if the user doesn't exist
        return fail!('Invalid email or password.') unless (uk_user_details and uk_user_details["status"] == "success")

        #
        # mapping.to is a wrapper over the resource model
        #
        
        # A UK user exists, so first try and find if they already have a local rails account
        resource = mapping.to.find_for_database_authentication(:uk_id => uk_user_details["data"]["id"])
        
        # Rails.logger.debug "Resource pre-build: #{resource.to_json}"

        if not resource
          Rails.logger.debug "NOT FOUND: No rails account for uk_id: #{uk_user_details["data"]["id"]}"
          # Try by email address to catch any UK users that already had a digital.newint.com.au account
          resource = mapping.to.find_for_database_authentication(:email => uk_user_details["data"]["email"])
        end

        if not resource
          Rails.logger.debug "NOT FOUND: No rails account for email: #{uk_user_details["data"]["email"]}"
          # If they don't have a rails account, make one
          resource = mapping.to.new
          build_user_from_uk_info(resource, uk_user_details)

          unless resource.save
            fail!(resource.unauthenticated_message)
            Rails.logger.debug "FAILED: #{resource.unauthenticated_message}"
          end

          # Rails.logger.debug "Resource built: #{resource.to_json}"
        else
          Rails.logger.debug "User found: #{resource.username}"
          # They do have an account, so lets sync it with the UK data.
          if uk_user_details["data"]["email"]
            resource.email = uk_user_details["data"]["email"]
          else
            resource.email = generate_uk_email_address(uk_user_details["data"]["id"])
          end
          resource.uk_expiry = parse_expiry_from_uk_details(uk_user_details["data"]["expiry"])
          resource.uk_id = uk_user_details["data"]["id"]
        end

        return fail! unless resource

        # validate is a method defined in Devise::Strategies::Authenticatable. It takes
        #a block which must return a boolean value.
        #
        # If the block returns true the resource will be loged in
        # If the block returns false the authentication will fail!
        #
        if validate(resource){ validate_resource(resource) }
          success!(resource)
        else
          fail!
        end
      end

      private

      def remote_authentication_uk_user(authentication_hash)
        # Returns a hash with the result

        cleaned_login = authentication_hash[:login].gsub(/[^0-9A-Za-z ]/, '')
        cleaned_password = authentication_hash[:password].gsub(/[^0-9A-Za-z ]/, '')

        api_endpoint = ENV["NI_UK_SUBSCRIBER_API"] + URI::escape(cleaned_login) + "/" + URI::escape(cleaned_password) + "/" + ENV["NI_UK_SUBSCRIBER_API_SECRET"]

        begin
          response = HTTParty.get(
            api_endpoint,
            headers: {}
          )
        rescue => e
          # Send admin email
          UserMailer.uk_server_error(e).deliver
          Rails.logger.debug "HTTParty FAILED! Error: " + e.to_s
          fail!
        end
        
        if response and response.code == 200
          # Success!
          body = JSON.parse(response.body)
          Rails.logger.debug "SUCCESS! Found UK user: #{body["data"]["lname"]}, expiry: #{body["data"]["expiry"]}"
          return body
        elsif response and response.code == 404
          # User not found!
          body = response.body
          Rails.logger.debug "NOT FOUND! Can't find UK user with ID: #{cleaned_login}, lname: #{cleaned_password}"
          return body
        else
          # FAIL! server error.
          Rails.logger.debug "FAIL! UK Response code: #{response.code unless !response}"
          return nil
        end
      end

      def build_user_from_uk_info(user, uk_info)
        if user and uk_info
          if uk_info["data"]["email"]
            user.email = uk_info["data"]["email"]
          else
            user.email = generate_uk_email_address(uk_info["data"]["id"])
          end
          user.username = uk_info["data"]["fname"] + uk_info["data"]["lname"] + "_" + uk_info["data"]["id"]
          user.password = Devise.friendly_token
          user.password_confirmation = nil # So that Devise automatically encrypts the new password
          user.uk_expiry = parse_expiry_from_uk_details(uk_info["data"]["expiry"])
          user.uk_id = uk_info["data"]["id"]
        end
      end

      def validate_resource(resource)
        if not resource.email.nil?
          return true
        else
          return false
        end
      end

      def parse_expiry_from_uk_details(uk_info)
        DateTime.strptime(uk_info, "%Y-%m-%d")
      end

      def generate_uk_email_address(uk_id)
        "tech+no_email_subscriber_id#{uk_id}@newint.org"
      end

    end
  end
end
