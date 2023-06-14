class Recommendation < ApplicationRecord
  has_many :recommendation_watch_lists
  has_many :watch_lists, through: :recommendation_watch_lists

  belongs_to :query
  belongs_to :user
end
