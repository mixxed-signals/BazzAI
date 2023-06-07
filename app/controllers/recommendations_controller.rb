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
    @user = current_user
    @query = Query.new
  end

  def create
    @genres = GENRES
    @user = current_user
    @query = Query.new(query_params)
    @query.user_id = @user.id
    if @query.save
      redirect_to search_result_path(@query)
    else
      render :search
    end
  end

  def index
    @query = Query.find(params[:id])
    @mood = MOOD[@query.happiness]
  end

  def show
  end

  private

  def query_params
    genres = Array(params[:query][:genre]).join(", ") # Convert the selected genres to a single string stored in column genre
    params.require(:query).permit(:user_id, :medium, :time, :audience, :year_after, :year_before, :year_option, :happiness, :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3, :other).merge(genre: genres)
  end
end
