class RecommendationsController < ApplicationController
  OMDB_API_KEY = ENV['OMDB_API_KEY']
  X_RAPIDAPI_KEY = ENV['X_RAPIDAPI_KEY']
  X_RAPIDAPI_HOST = ENV['X_RAPIDAPI_HOST']

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
    @query = Query.new(query_params)
    @query.user = current_user
    if @query.save
      redirect_to search_result_path(@query)
      create_openai_request(@query)
    else
      render :search
    end
  end

  def index
    @query = Query.find(params[:id])
    @mood = MOOD[@query.happiness]
    @display_prompt = create_display_prompt(@query, @mood)

    @recommendations = Recommendation.where(query_id: @query.id)
    @more_prompt = create_more_like_this_prompt(@query, @mood)
    @more_recommendations = create_more_like_this_openai_request(@query)
  end

  def show
    @recommendation = Recommendation.find(params[:id])
    get_streaming_availability(@recommendation.imdbID)
    # platform_image(platform)
  end

  private

  def query_params
    params.require(:query).permit(
      :user_id, :time, :year_after, :year_before, :year_option, :happiness,
      :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3,
      :other, :audience, :medium
    ).tap do |query_params|
      query_params[:genre] = sanitize_genre_params(params[:query][:genre])
      query_params[:streaming_platform] = sanitize_genre_params(params[:query][:streaming_platform])
    end
  end

  def sanitize_genre_params(genre_params)
    genre_params.reject { |_, value| value == "0" }.keys.join(", ")
  end

  def create_prompt(query, mood)
    prompt_parts = [
      "Show me a list of 10 real #{query.medium}, just the titles in a string separated by a dot and a space '. ',",
      "and never put the #{query.medium} year or episode, use this information about me:",
      ("Movie time: #{query.time} minutes." if query.time.present?),
      ("Genres: #{query.genre}." if query.genre.present?),
      ("I want a movie that makes me feel: #{mood}." if mood.present?),
      ("I'm going to watch this movie as: #{query.audience}." if query.audience.present?),
      ("Level of concentration I need to watch the movie: #{query.intensity}/10." if query.intensity.present?),
      ("I want the movie to be experimental and non-mainstream on a level: #{query.novelty}/10." if query.novelty.present?),
      ("I watched these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3} and I enjoyed them."),
      ("Take them into account but don't suggest them to me again." if query.recent_movie1.present? || query.recent_movie2.present? || query.recent_movie3.present?),
      ("Other information about myself and my day to filter this movie: #{query.other}." if query.other.present?),
      "Separate the movies with a dot and a space '. '."
    ]

    prompt_parts.compact.join("\n")
  end

  def create_display_prompt(query, mood)
    "Hey Bazzy! Can you recommend me #{query.medium}?\n" \
    "I only have around #{query.time} minutes to spare, and I'll be watching this movie as \"#{query.audience}\"\n" \
    "The genres I'm in the mood for are: #{query.genre}. And I'm willing to focus on a level of #{query.intensity}/10.\n" \
    "My general mood right now could be described as \"#{mood}\", and I'm feeling like watching something experimental on a level of #{query.novelty}/10.\n" \
    "By the way, I enjoyed these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}.\n" \
    "Also, this is a bit more information about myself and my day: #{query.other}."
  end

  def create_more_like_this_prompt(query, mood)
    my_prompt = "Can you recommend me 3 more #{query.medium} like #{@recommendations.last.movie_name}?"
    return my_prompt
  end

  def create_recomedation(response, query)
    movies = response.map do |movie_name|
      data = create_omdb_request(movie_name)
      next if data.nil?

      create_recomedation_class(movie_name, data, query)&.tap(&:save)
    end
    movies.compact
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
      trailer_link: get_trailer_link(data['imdbID']),
      rotten_score: '99%', # We need to fix this
      imdb_score: data['imdbRating'].present? ? data['imdbRating'] : nil,
      query_id: query
    )
  end

  def get_trailer_link(imdb_id)
    url = "https://api.kinocheck.de/movies?imdb_id=#{imdb_id}&categories=trailer"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    data['trailer']&.fetch('youtube_video_id', nil) { |trailer| "https://www.youtube.com/embed/#{trailer['youtube_video_id']}" }
  rescue StandardError => e
    Rails.logger.error("Error fetching movie details: #{e.message}")
    nil
  end

def get_streaming_availability(imdbID)
  url = URI("https://streaming-availability.p.rapidapi.com/v2/get/basic?country=de&imdb_id=#{imdbID}&output_language=en")
  request = Net::HTTP::Get.new(url)
  request["X-RapidAPI-Key"] = X_RAPIDAPI_KEY
  request["X-RapidAPI-Host"] = X_RAPIDAPI_HOST
  response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
    http.request(request)
  end
  @data = JSON.parse(response.body)
  # @data = {
  # "result" => {
  #   "type" => "movie",
  #   "title" => "The Dark Knight",
  #   "overview" => "Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle the remaining criminal organizations that plague the streets. The partnership proves to be effective, but they soon find themselves prey to a reign of chaos unleashed by a rising criminal mastermind known to the terrified citizens of Gotham as the Joker.",
  #   "streamingInfo" => {
  #     "de" => {
  #       "hbo" => [
  #         {
  #           "type" => "subscription",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "netflix" => [
  #         {
  #           "type" => "subscription",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "disney" => [
  #         {
  #           "type" => "subscription",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "hulu" => [
  #         {
  #           "type" => "subscription",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "wow" => [
  #         {
  #           "type" => "subscription",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #           price: "0"
  #         }
  #       ],
  #       "mubi" => [
  #         {
  #           "type" => "subscription",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "hbo" => [
  #         {
  #           "type" => "buy",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "netflix" => [
  #         {
  #           "type" => "buy",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "disney" => [
  #         {
  #           "type" => "buy",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "hulu" => [
  #         {
  #           "type" => "buy",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "wow" => [
  #         {
  #           "type" => "buy",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "mubi" => [
  #         {
  #           "type" => "buy",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "hbo" => [
  #         {
  #           "type" => "rent",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #           "price" => "3.99",
  #         }
  #       ],
  #       "netflix" => [
  #         {
  #           "type" => "rent",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "disney" => [
  #         {
  #           "type" => "rent",
  #           "link" => "https://www.netflix.com/title/70079583/",
  #         }
  #       ],
  #       "hulu" => [
  #         {
  #           "type" => "rent",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "wow" => [
  #         {
  #           "type" => "rent",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ],
  #       "mubi" => [
  #         {
  #           "type" => "rent",
  #           "link" => "https://www.netflix.com/title/70079583/"
  #         }
  #       ]
  #     }
  #   },
  #   "cast" => ["Christian Bale", "Heath Ledger", "Michael Caine", "Gary Oldman", "Aaron Eckhart", "Maggie Gyllenhaal", "Morgan Freeman"],
  #   "year" => 2008,
  #   "advisedMinimumAudienceAge" => 12,
  #   "imdbId" => "tt0468569",
  #   "imdbRating" => 90,
  #   "imdbVoteCount" => 2714996,
  #   "tmdbId" => 155,
  #   "tmdbRating" => 85,
  #   "originalTitle" => "The Dark Knight",
  #   "backdropPath" => "/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
  #   "backdropURLs" => {
  #     "1280" => "https://image.tmdb.org/t/p/w1280/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
  #     "300" => "https://image.tmdb.org/t/p/w300/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
  #     "780" => "https://image.tmdb.org/t/p/w780/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
  #     "original" => "https://image.tmdb.org/t/p/original/dqK9Hag1054tghRQSqLSfrkvQnA.jpg"
  #   },
  #   "genres" => [
  #     {"id" => 28, "name" => "Action"},
  #     {"id" => 80, "name" => "Crime"},
  #     {"id" => 18, "name" => "Drama"}
  #   ],
  #   "originalLanguage" => "en",
  #   "countries" => ["GB", "US"],
  #   "directors" => ["Christopher Nolan"],
  #   "runtime" => 152,
  #   "youtubeTrailerVideoId" => "kmJLuwP3MbY",
  #   "youtubeTrailerVideoLink" => "https://www.youtube.com/watch?v=kmJLuwP3MbY",
  #   "posterPath" => "/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #   "posterURLs" => {
  #     "154" => "https://image.tmdb.org/t/p/w154/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #     "185" => "https://image.tmdb.org/t/p/w185/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #     "342" => "https://image.tmdb.org/t/p/w342/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #     "500" => "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #     "780" => "https://image.tmdb.org/t/p/w780/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #     "92" => "https://image.tmdb.org/t/p/w92/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
  #     "original" => "https://image.tmdb.org/t/p/original/qJ2tW6WMUDux911r6m7haRef0WH.jpg"
  #   },
  #   "tagline" => "Welcome to a world without rules."
  # }
  # }
end

def platform_image(platform)
  case platform
    when 'apple'
        "Apple.png"
    when 'disney'
        "Disney.png"
    when 'mubi'
        "mubi.png"
    when 'netflix'
        "Netflix.png"
    when 'prime'
        "Amazon Prime.png"
    when 'hbo'
        "HBO Max.png"
    when 'hulu'
        "Hulu.png"
    when 'peacock'
        "Peacock.png"
    when 'youtube'
        "YouTube.png"
    when 'wow'
        "wow.png"
  end
end

  def create_response_arr(response)
    response.gsub(/(\A[\d.,]+|\n)/, '').split(". ").map { |movie| movie.gsub(/\A[\d.,]+/, '').strip }
  end

  def create_omdb_request(movie_name)
    formatted_movie_name = URI.encode_www_form_component(movie_name)
    url = "http://www.omdbapi.com/?t=#{formatted_movie_name}&apikey=#{OMDB_API_KEY}"
    uri = URI(url)

    response = Net::HTTP.get(uri)
    JSON.parse(response)
  rescue StandardError => e
    Rails.logger.error("Error fetching movie details: #{e.message}")
    nil
  end

  def create_openai_request(query)
    mood = MOOD[query.happiness]
    response = OpenaiService.new(create_prompt(query, mood)).call
    create_recomedation(create_response_arr(response), query.id)
  end

  def create_more_like_this_openai_request(query)
    mood = MOOD[@query.happiness]
    response = OpenaiService.new(create_more_like_this_prompt(query, mood)).call
    create_recomedation(create_response_arr(response), query.id)
  end
end
