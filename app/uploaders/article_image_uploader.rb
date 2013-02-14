# encoding: utf-8

class ArticleImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  #storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    # "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  
    # "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  process :store_geometry
  def store_geometry
    if @file
      img = ::Magick::Image::read(@file.file).first
      if model
        model.width = img.columns
        model.height = img.rows
      end
    end
  end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Use RMagick
  version :halfwidth do
    process :resize_to_limit => [340, nil]
    # process :resize_to_fill => [945, 400]
  end

  version :threehundred do
    process :resize_to_limit => [300, nil]
  end

  # Retina display @2x version
  version :halfwidth2x do
    process :resize_to_limit => [680, nil]
    def full_filename (for_file = model.article_image.file)
      "halfwidth_#{for_file.chomp(File.extname(for_file))}@2x#{File.extname(for_file)}"
    end
  end

  version :threehundred2x do
    process :resize_to_limit => [600, nil]
    def full_filename (for_file = model.article_image.file)
      "threehundred_#{for_file.chomp(File.extname(for_file))}@2x#{File.extname(for_file)}"
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
