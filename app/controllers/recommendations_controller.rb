class RecommendationsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[search create index show]

  GENRES = [
    "Action",
    "Adventure",
    "Animation",
    "Anime",
    "Award-Winning",
    "Biography",
    "Classic",
    "Comedy",
    "Coming-of-Age",
    "Crime",
    "Cult",
    "Cult Classic",
    "Documentary",
    "Drama",
    "Family",
    "Fantasy",
    "Film-Noir",
    "History",
    "Horror",
    "Independent",
    "International",
    "Mystery",
    "Musical",
    "Noir",
    "Psychological",
    "Queer",
    "Reality",
    "Romance",
    "Rom-Com",
    "Science Fiction",
    "Sci-Fi",
    "Spy",
    "Superhero",
    "Supernatural",
    "Suspense",
    "Teen",
    "Thriller",
    "True Crime",
    "War",
    "Western"
  ].freeze

  MOOD = [
    "Depressed",
    "Sad",
    "Melancholic",
    "Bummed Out",
    "Pensive",
    "Meh",
    "Chill",
    "Neutral",
    "Happy",
    "Excited",
    "Thrilled",
    "Over the Moon"
  ]

  def search
    @genres = GENRES
    @query = Query.new
  end

  def create
    @genres = GENRES
    @query = Query.new(query_params)
    @query.save!
    redirect_to recommendations_path
  end

  def index
    @query = Query.last
    @mood = MOOD[@query.happiness]
  end

  def show
  end

  private

  def query_params
    params.require(:query).permit(:medium, :time, :audience, :genres, :year_option, :year_before, :year_after, :happiness, :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3, :other)
  end
end
