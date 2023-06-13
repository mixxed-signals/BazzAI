class Recommendation < ApplicationRecord
  has_many :watch_lists
  belongs_to :query
  belongs_to :user
end
