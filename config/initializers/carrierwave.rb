CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['S3_KEY'],
    :aws_secret_access_key  => ENV['S3_SECRET'],
    :region                 => ENV['S3_REGION']
  }
  if Rails.env.production?
    config.storage = :fog
    config.fog_directory  = ENV['S3_BUCKET']
    # Use CloudFront CDN
    config.asset_host = "https://#{ENV['CLOUDFRONT_SERVER']}.cloudfront.net"
    config.fog_public = true
    config.fog_attributes = {'Cache-Control'=>'max-age=31557600'}
    # config.fog_host = 's3-ap-northeast-1.amazonaws.com'
  else
    config.storage = :file
  end
end