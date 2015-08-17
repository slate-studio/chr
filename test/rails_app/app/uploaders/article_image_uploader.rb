class ArticleImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  # include Character::UploaderThumbnail

  def store_dir
    "uploads/articles_images/#{model.id}"
  end

  version :regular do
    process :resize_to_fill => [300, 188]
  end

  version :regular_2x do
    process :resize_to_fill => [600, 375]
  end
end
