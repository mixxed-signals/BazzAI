class AddWatchListToRecommendations < ActiveRecord::Migration[7.0]
  def change
    add_reference :recommendations, :watch_list, foreign_key: true, null: true
  end
end
