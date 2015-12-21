CarrierWave.configure do |config|
  config.storage = :file
  config.cache_dir = "#{Rails.root}/public/uploads/tmp"

  if Rails.env.test?
    config.cache_dir = "#{Rails.root}/public/uploads/tmp/test"
    config.enable_processing = false
  end

  if Rails.env.production? || Rails.env.staging?
    if ENV.has_key? "FOG_DIRECTORY"
      config.storage = :fog
      config.fog_directory = ENV.fetch("FOG_DIRECTORY")
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
      }
    end
  end
end
