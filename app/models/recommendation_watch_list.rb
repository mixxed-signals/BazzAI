class RecommendationWatchList < ApplicationRecord
  belongs_to :recommendation
  belongs_to :watch_list
end
