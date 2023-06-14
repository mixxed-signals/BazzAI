class Recommendation < ApplicationRecord
  belongs_to :watch_lists
  belongs_to :query
  belongs_to :user
end
