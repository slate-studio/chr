class ArticleImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    "uploads/articles_images/#{ model.id }"
  end

  version :thumbnail_2x do
    process :resize_to_fill => [600, 380]
  end

end
