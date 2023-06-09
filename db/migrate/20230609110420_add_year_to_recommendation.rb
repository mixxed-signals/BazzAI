class AddYearToRecommendation < ActiveRecord::Migration[7.0]
  def change
    add_column :recommendations, :year, :string
  end
end
