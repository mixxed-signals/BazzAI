class RecommendationsController < ApplicationController
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
    @query.user = @user
    # raise
    if @query.save
      redirect_to search_result_path(@query)
    else
      render :search
    end
  end

  def index
    @omdb_key = omdb_key
    @query = Query.find(params[:id])
    @mood = MOOD[@query.happiness]
    @prompt = create_prompt(@query, @mood)
    @response = 'Lion King, The Godfather, The Shawshank Redemption, The Dark Knight, Pulp Fiction, Schindler\'s List'
    # @response = OpenaiService.new(create_prompt(@query, @mood)).call
    @response = @response.split(", ")
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
  end

  private

  def omdb_key
    ENV.fetch('OMDB_API_KEY')
  end

  def query_params
    genres = Array(params[:query][:genre]).join(", ") # Convert the selected genres to a single string stored in column genre
    params.require(:query).permit(:user_id, :medium, :time, :audience, :year_after, :year_before, :year_option, :happiness, :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3, :other).merge(genre: genres)
  end

  def create_prompt(query, mood)
    request_part = "Show me a list of 10 real #{query.medium}, just the titles in a string separetes the movies using ',', and never put the #{query.medium} year or episode, use this informations about me:"

    movie_time = "Movie time: #{query.time} minutes"
    movie_genre = "Genre: #{query.genre}"
    movie_mood = "Movie that makes me feel: #{mood}"
    movie_audience = "I gonna watch this movie: #{query.audience}"
    movie_concetrate = "Concentrate i need to watch the movie: #{query.intensity}"
    movie_novelty = "Non-mainstream on a leve: #{query.novelty}"
    recent_movies = "I watched this movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}"
    other = "Other informations to filter this movie: #{query.other}"

    return request_part + "\n" + movie_time + "\n" + movie_genre + "\n" + movie_mood + "\n" + movie_audience + "\n" + movie_concetrate + "\n" + movie_novelty + "\n" + recent_movies + "\n" + other
  end
end
