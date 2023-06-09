class AddColumnsToRecommendations < ActiveRecord::Migration[7.0]
  def change
    add_column :recommendations, :imdbID, :string
    add_column :recommendations, :genre, :string
    add_column :recommendations, :rating, :string
    add_column :recommendations, :image, :string
    add_column :recommendations, :awards, :string
    add_column :recommendations, :runtime, :string
    add_column :recommendations, :synopsis, :text
    add_column :recommendations, :director, :string
    add_column :recommendations, :writer, :string
    add_column :recommendations, :actors, :string
    add_column :recommendations, :rotten_score, :string
    add_column :recommendations, :imdb_score, :string
    add_column :recommendations, :trailer_link, :string
  end
end
