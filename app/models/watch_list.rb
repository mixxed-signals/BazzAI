class WatchList < ApplicationRecord
  belongs_to :user
  belongs_to :recommendation

  validates :user, presence: true
end
