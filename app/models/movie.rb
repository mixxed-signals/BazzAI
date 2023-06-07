class Movie < ApplicationRecord
  validates :title, presence: true, uniqueness: true
end
