class Query < ApplicationRecord
  belongs_to :user
  has_many :recommendations
  MEDIUMS = ["Movie", "TV Show"]
  AUDIENCE = ["Just Me", "Couple", "Family"]
  STREAMING_PLATFORMS = ["netflix", "hulu", "prime", "hbo", "disney", "apple", "peacock", "youtube", "wow", "mubi"]
end
