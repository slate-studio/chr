class Article
include Mongoid::Document
include Mongoid::Timestamps
include Mongoid::Search

include Ants::Id
include Ants::Orderable

  ## Attributes
  field :title
  field :description
  field :body_html

  ## Uploader
  mount_uploader :image, ArticleImageUploader


  # default_scope -> { asc(:_position) }
  scope :sport_articles, -> { where(description: 'Sport News') }
  
  search_in :title, :description

  index({ description: 1 })

  def _list_item_title
    title
  end


  def _list_item_thumbnail
    image? ? image.regular_2x.url : ''
  end


end