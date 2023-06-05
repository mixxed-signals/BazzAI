class CreateQueries < ActiveRecord::Migration[7.0]
  def change
    create_table :queries do |t|
      t.string :medium
      t.integer :time
      t.string :audience
      t.string :genre
      t.integer :happiness
      t.integer :intensity
      t.integer :novelty
      t.string :recent_movie1
      t.string :recent_movie2
      t.string :recent_movie3
      t.text :other

      t.timestamps
    end
  end
end
