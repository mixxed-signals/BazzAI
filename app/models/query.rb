class Query < ApplicationRecord
  validates :year_before, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: 2023 }
  validates :year_after, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: 2023 }
end
