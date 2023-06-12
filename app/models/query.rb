class Query < ApplicationRecord
  belongs_to :user
  has_many :recommendations
  MEDIUMS = ["Movie", "TV Show"]
  AUDIENCE = ["Just Me", "Couple", "Family"]
  STREAMING_PLATFORMS = ["Netflix", "Hulu", "Amazon Prime", "HBO Max", "Disney", "Apple", "Peacock", "YouTube"]
end
