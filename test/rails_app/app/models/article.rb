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


  ## Search
  search_in :title, :description


  ## Scopes
  scope :sport_articles, -> { where(description: 'Sport News') }


  ## Indexes
  index({ description: 1 })


  ## Helpers
  def _list_item_title
    title
  end


  def _list_item_thumbnail
    image? ? image.thumbnail_2x.url : ''
  end

end




