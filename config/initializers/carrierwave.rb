CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['S3_KEY'],
    :aws_secret_access_key  => ENV['S3_SECRET'],
    :region                 => 'tokyo'
  }
  config.fog_directory  = 'nirailsapp'
  config.fog_public = true
  # config.fog_host = 's3-ap-northeast-1.amazonaws.com'
  if Rails.env.production?
    config.storage = :fog
  else
    config.storage = :file
  end
end