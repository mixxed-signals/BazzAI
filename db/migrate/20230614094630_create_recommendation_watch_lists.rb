class CreateRecommendationWatchLists < ActiveRecord::Migration[7.0]
  def change
    create_table :recommendation_watch_lists do |t|
      t.belongs_to :recommendation, null: false, foreign_key: true
      t.belongs_to :watch_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
