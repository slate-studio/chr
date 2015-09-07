CarrierWave.configure do |config|

  # DEVELOPMENT
  config.storage   = :file
  config.cache_dir = "#{Rails.root}/public/uploads/tmp"

  if Rails.env.test?
    # TEST
    config.cache_dir = "#{Rails.root}/public/uploads/tmp/test"
    config.enable_processing = false

  elsif Rails.env.production? || Rails.env.staging?
    # PRODUCTION & STAGING
    config.storage         = :fog
    config.fog_directory   = ENV.fetch('FOG_DIRECTORY')
    config.asset_host      = ENV.fetch('ASSET_HOST')
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID'),
      aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
    }
  end

end
