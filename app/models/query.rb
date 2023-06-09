class Query < ApplicationRecord
  belongs_to :user
  has_many :recommendations
  MEDIUMS = ["Movie", "TV Show"]
  AUDIENCE = ["Just Me", "Couple", "Family"]
end
