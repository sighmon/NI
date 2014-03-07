# encoding: utf-8

class ZipUploader < CarrierWave::Uploader::Base

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  # Only use S3 storage via fog.
  storage :fog

  def initialize(*)
    super

    self.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => ENV['S3_KEY'],
      :aws_secret_access_key  => ENV['S3_SECRET'],
      :region                 => ENV['S3_REGION']
    }

    self.fog_directory = ENV['S3_ZIP_BUCKET']
    self.fog_public = false
  end

  # Use the zip bucket
  # fog_host = 's3-ap-southeast-2.amazonaws.com'
  # fog_directory = 'nirailszip'

  # Make it private
  # fog_public = false

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # def store_dir
  #   "#{model.class.to_s.underscore}/#{model.id}"
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(zip)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
