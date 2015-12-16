CarrierWave.configure do |config|
  config.cache_dir = "#{Rails.root}/public/uploads/tmp"

  # DEVELOPMENT
  if Rails.env.development?
    config.storage = :file
  end

  # TEST
  if Rails.env.test?
    config.cache_dir = "#{Rails.root}/public/uploads/tmp/test"
    config.enable_processing = false

  # PRODUCTION & STAGING
  elsif Rails.env.production? || Rails.env.staging?
    config.storage = :fog
    config.fog_directory = ENV.fetch('FOG_DIRECTORY')
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
    }
  end
end