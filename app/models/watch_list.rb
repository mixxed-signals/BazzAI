class WatchList < ApplicationRecord
  belongs_to :user
  has_many :recommendation

  validates :user, presence: true
end
