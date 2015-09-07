CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false
  config.cache_dir = "#{Rails.root}/public/uploads/tmp/test"
end
