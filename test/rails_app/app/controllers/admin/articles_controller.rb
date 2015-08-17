class Admin::ArticlesController < Admin::BaseController
  mongosteen
  has_scope :sport_articles, type: :boolean
  json_config methods: [ :test_method ]
end