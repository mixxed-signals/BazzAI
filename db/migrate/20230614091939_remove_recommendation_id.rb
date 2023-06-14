class RemoveRecommendationId < ActiveRecord::Migration[7.0]
  def change
    remove_column :watch_lists, :recommendation_id
  end
end
