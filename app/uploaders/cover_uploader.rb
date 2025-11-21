# encoding: utf-8

class CoverUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  # storage :file
  # storage :fog

  # storage (Rails.env.production?) ? :fog : :file 

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    "fallback/" + [version_name, "default_cover.jpg"].compact.join('_')
  end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process scale: [50, 50]
  # end
  # Use RMagick
  version :thumb do
    process resize_to_limit: [200, 200]
  end

  # Retina display :thumb @2x version
  version :thumb2x do
    process resize_to_limit: [400,400]
    def full_filename (for_file = model.cover.file) 
      "thumb_#{for_file.chomp(File.extname(for_file))}@2x#{File.extname(for_file)}"
    end
  end

  # Make a PNG version for NewsStand
  version :png do
    process convert: 'png'
    def full_filename (for_file = model.cover.file)
      "#{for_file.chomp(File.extname(for_file))}.png"
    end
  end

  version :tiny do
    process resize_to_limit: [75, 75]
  end

  # Retina display :tiny @2x version
  version :tiny2x do
    process resize_to_limit: [150, 150]
    def full_filename (for_file = model.cover.file) 
      "tiny_#{for_file.chomp(File.extname(for_file))}@2x#{File.extname(for_file)}"
    end
  end

  version :home do
    process resize_to_limit: [400, 400]
  end

  # Retina display :tiny @2x version
  version :home2x do
    process resize_to_limit: [800, 800]
    def full_filename (for_file = model.cover.file) 
      "home_#{for_file.chomp(File.extname(for_file))}@2x#{File.extname(for_file)}"
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
