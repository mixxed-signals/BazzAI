class WatchList < ApplicationRecord
  has_many :recommendation_watch_lists
  has_many :recommendations, through: :recommendation_watch_lists
  belongs_to :user

  validates :user, presence: true
end
