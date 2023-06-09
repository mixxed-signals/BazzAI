class RecommendationsController < ApplicationController
  OMDB_API_KEY = ENV['OMDB_API_KEY']

  GENRES = [
    "Acclaimed",
    "Action",
    "Adventure",
    "Animation",
    "Anime",
    "Biography",
    "Classic",
    "Comedy",
    "Crime",
    "Cult",
    "Documentary",
    "Drama",
    "Experimental",
    "Family",
    "Fantasy",
    "Film-Noir",
    "Gangster",
    "History",
    "Horror",
    "Independent",
    "International",
    "Music",
    "Mystery",
    "Musical",
    "Noir",
    "Psychological",
    "Queer",
    "Reality",
    "Romance",
    "Rom-Com",
    "Satire",
    "Sci-Fi",
    "Space",
    "Sports",
    "Spy",
    "Superhero",
    "Supernatural",
    "Suspense",
    "Thriller",
    "True Crime",
    "Western",
    "Youth"
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
    if @query.save
      redirect_to search_result_path(@query)
      @mood = MOOD[@query.happiness]
      @prompt = create_prompt(@query, @mood)
      @response = 'Lion King. The Godfather. The Shawshank Redemption. The Dark Knight. Pulp Fiction. Schindler\'s List'
      # @response = OpenaiService.new(create_prompt(@query, @mood)).call
      create_recomedation(create_response_arr(@response), @query.id)
    else
      render :search
    end
  end

  def index
    @query = Query.find(params[:id])
    @recommendations = Recommendation.where(query_id: @query.id)
  end

  def show
    @recommendation = Recommendation.find(params[:id])
  end

  private

  def query_params
    genres = Array(params[:query][:genre]).join(", ") # Convert the selected genres to a single string stored in column genre
    params.require(:query).permit(:user_id, :medium, :time, :audience, :year_after, :year_before, :year_option, :happiness, :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3, :other).merge(genre: genres)
  end

  def create_prompt(query, mood)
    request_part = "Show me a list of 10 real #{query.medium}, just the titles in a string separated by a dot and a space '. ', and never put the #{query.medium} year or episode, use this information about me:"

    movie_time = "Movie time: #{query.time} minutes." if query.time.present?
    movie_genre = "Genre: #{query.genre}." if query.genre.present?
    movie_mood = "Movie that makes me feel: #{mood}." if mood.present?
    movie_audience = "I'm going to watch this movie: #{query.audience}." if query.audience.present?
    movie_concentrate = "Concentrate, I need to watch the movie: #{query.intensity}/10." if query.intensity.present?
    movie_novelty = "Non-mainstream on a level: #{query.novelty}/10." if query.novelty.present?
    recent_movies = "I watched these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}." if query.recent_movie1.present? || query.recent_movie2.present? || query.recent_movie3.present?
    other = "Other information to filter this movie: #{query.other}." if query.other.present?

    separate_part = "Separate the movies with a dot and a space '. '."

    return "#{request_part}\n#{movie_time}\n#{movie_genre}\n#{movie_mood}\n#{movie_audience}\n#{movie_concentrate}\n#{movie_novelty}\n#{recent_movies}\n#{other}\n#{separate_part}"
  end

  def create_recomedation(response, query)
    movies = response.map do |movie_name|
      data = create_request(movie_name)
      break if data['Response'] == 'False'

      recommendation = create_recomedation_class(movie_name, data, query)
      recommendation.save
    end
    return movies
  end

  def get_link(imdb_id)
    url = "https://api.kinocheck.de/movies?imdb_id=#{imdb_id}&categories=trailer"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    return nil if data['trailer'].nil?
    "https://www.youtube.com/embed/#{data['trailer']['youtube_video_id']}"
  end

  def create_response_arr(response)
    response = response.gsub(/\.\d+/, '')
    response = response.gsub(/(\.\d+|\n)/, '')
    response = response.split(". ")
    return response
  end

  def create_request(movie_name)
    url = "http://www.omdbapi.com/?t=#{movie_name}&apikey=#{OMDB_API_KEY}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    return JSON.parse(response)
  end

  def create_recomedation_class(movie_name, data, query)
    Recommendation.new(
      user: current_user,
      movie_name: movie_name,
      imdbID: data['imdbID'],
      genre: data['Genre'],
      year: data['Year'],
      rating: data['Rated'],
      image: data['Poster'],
      awards: data['Awards'],
      runtime: data['Runtime'],
      synopsis: data['Plot'],
      director: data['Director'],
      writer: data['Writer'],
      actors: data['Actors'],
      trailer_link: get_link(data['imdbID']),
      rotten_score: '99%', # We need to fix this
      imdb_score: data['imdbRating'].present? ? data['imdbRating'] : nil,
      query_id: query
    )
  end
end
