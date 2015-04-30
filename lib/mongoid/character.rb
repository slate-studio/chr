module Mongoid
  module Character
    extend ActiveSupport::Concern

    included do
      include Mongoid::Timestamps
      include Mongoid::SerializableId
      include ActionView::Helpers::DateHelper
    end


    def _list_item_title
      first_non_id_attribute = self.attributes.keys.select { |k| k != '_id' }.first
      self[first_non_id_attribute].to_s
    end


    def _list_item_subtitle
      "created #{ time_ago_in_words(created_at) } ago" if created_at
    end


    def _list_item_thumbnail
    end
  end
end




