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
    # @more_prompt = create_more_like_this_prompt(@query, @mood)
    # @more_recommendations = create_more_like_this_openai_request(@query)
  end

  def show
    @recommendation = Recommendation.find(params[:id])
    get_streaming_availability(@recommendation.imdbID)
  end

  private

  def query_params
    params.require(:query).permit(
      :user_id, :time, :year_after, :year_before, :year_option, :happiness,
      :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3,
      :other, :audience, :medium
    ).tap do |query_params|
      query_params[:genre] = sanitize_params(params[:query][:genre])
      query_params[:streaming_platform] = sanitize_params(params[:query][:streaming_platform])
    end
  end

  def sanitize_params(params)
    params.reject { |_, value| value == "0" }.keys.join(", ")
  end

  def create_prompt(query, mood)
    prompt_parts = [
      "Show me a list of 10 real #{query.medium}, just the titles of the movie in a hash format like:{\"movie1\":\"Movie name\", ...}.",
      "Always list real movies, NEVER your preference.",
      "And, always use double quotion to wrap the movie name but use single quotes in the movie names.",
      "and never put the #{query.medium} year or episode, use this information about me:",
      ("Movie time: #{query.time} minutes." if query.time.present?),
      ("Genres: #{query.genre}." if query.genre.present?),
      ("I want a movie that makes me feel: #{mood}." if mood.present?),
      ("I'm going to watch this movie as: #{query.audience}." if query.audience.present?),
      ("Level of concentration I need to watch the movie: #{query.intensity}/10." if query.intensity.present?),
      ("I want the movie to be experimental and non-mainstream on a level: #{query.novelty}/10." if query.novelty.present?),
      "I watched these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3} and I enjoyed them.",
      ("Take them into account but don't suggest them to me again." if query.recent_movie1.present? || query.recent_movie2.present? || query.recent_movie3.present?),
      ("Other information about myself and my day to filter this movie: #{query.other}." if query.other.present?),
      ("I want to watch this movie on: #{query.streaming_platform}." if query.streaming_platform.present?)
    ]
    prompt_parts.compact.join("\n")
  end

  def create_display_prompt(query, mood)
    prompt = ""

    prompt += "Hey! Seems like you're looking for a #{query.medium} recommendation.\n" if query.medium.present?
    prompt += "You only have around #{query.time} minutes to spare, and you'll be watching this movie as \"#{query.audience}\".\n" if query.time.present? && query.audience.present?
    prompt += "You're in the mood for #{query.genre}, and your general mood right now could be described as \"#{mood}\".\n" if query.genre.present? && mood.present?
    prompt += "You feel like watching something experimental on a level of #{query.novelty}/10.\n" if query.novelty.present?
    prompt += "I'll take into account that you enjoyed these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}.\n" if query.recent_movie1.present? || query.recent_movie2.present? || query.recent_movie3.present?
    prompt += "And that this is how you're feeling today: #{query.other}.\n" if query.other.present?

    prompt
  end



  def create_more_like_this_prompt(query, mood)

    my_prompt = "Can you recommend me 3 more #{query.medium} like #{@recommendations.last.movie_name}?"
    return my_prompt
  end

  def create_recomedation(response, query)
    p response
    response.each do |_key, value|
      data = create_omdb_request(value)
      next if data.nil?

      create_recomedation_class(data, query)&.tap(&:save)
    end
  end

  def create_recomedation_class(data, query)
    Recommendation.new(
      user: current_user,
      movie_name: data['Title'],
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
  # url = URI("https://streaming-availability.p.rapidapi.com/v2/get/basic?country=de&imdb_id=#{imdbID}&output_language=en")
  # request = Net::HTTP::Get.new(url)
  # request["X-RapidAPI-Key"] = X_RAPIDAPI_KEY
  # request["X-RapidAPI-Host"] = X_RAPIDAPI_HOST
  # response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
  #   http.request(request)
  # end
  # @data = JSON.parse(response.body)
  @data = {
    "result" => {
    "type" => "movie",
    "title" => "The Dark Knight",
    "overview" => "Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle the remaining criminal organizations that plague the streets. The partnership proves to be effective, but they soon find themselves prey to a reign of chaos unleashed by a rising criminal mastermind known to the terrified citizens of Gotham as the Joker.",
    "streamingInfo" => {
      "de" => {
        "hbo" => [
          {
            "type" => "subscription",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}",
          }
        ],
        "netflix" => [
          {
            "type" => "subscription",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}",
          }
        ],
        "disney" => [
          {
            "type" => "subscription",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}",
          }
        ],

        "wow" => [
          {
            "type" => "subscription",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}",
          }
        ],

        "hulu" => [
          {
            "type" => "buy",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}"
          }
        ],
        "wow" => [
          {
            "type" => "buy",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}"
          }
        ],
        "mubi" => [
          {
            "type" => "buy",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}"
          }
        ],
 
        "apple" => [
          {
            "type" => "rent",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}"
          }
        ],
        "prime" => [
          {
            "type" => "rent",
            "link" => "https://www.netflix.com/title/70079583/#{SecureRandom.hex(8)}"
          }
        ]
      }
    },
    "cast" => ["Christian Bale", "Heath Ledger", "Michael Caine", "Gary Oldman", "Aaron Eckhart", "Maggie Gyllenhaal", "Morgan Freeman"],
    "year" => 2008,
    "advisedMinimumAudienceAge" => 12,
    "imdbId" => "tt0468569",
    "imdbRating" => 90,
    "imdbVoteCount" => 2714996,
    "tmdbId" => 155,
    "tmdbRating" => 85,
    "originalTitle" => "The Dark Knight",
    "backdropPath" => "/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
    "backdropURLs" => {
      "1280" => "https://image.tmdb.org/t/p/w1280/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
      "300" => "https://image.tmdb.org/t/p/w300/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
      "780" => "https://image.tmdb.org/t/p/w780/dqK9Hag1054tghRQSqLSfrkvQnA.jpg",
      "original" => "https://image.tmdb.org/t/p/original/dqK9Hag1054tghRQSqLSfrkvQnA.jpg"
    },
    "genres" => [
      {"id" => 28, "name" => "Action"},
      {"id" => 80, "name" => "Crime"},
      {"id" => 18, "name" => "Drama"}
    ],
    "originalLanguage" => "en",
    "countries" => ["GB", "US"],
    "directors" => ["Christopher Nolan"],
    "runtime" => 152,
    "youtubeTrailerVideoId" => "kmJLuwP3MbY",
    "youtubeTrailerVideoLink" => "https://www.youtube.com/watch?v=kmJLuwP3MbY",
    "posterPath" => "/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
    "posterURLs" => {
      "154" => "https://image.tmdb.org/t/p/w154/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
      "185" => "https://image.tmdb.org/t/p/w185/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
      "342" => "https://image.tmdb.org/t/p/w342/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
      "500" => "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
      "780" => "https://image.tmdb.org/t/p/w780/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
      "92" => "https://image.tmdb.org/t/p/w92/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
      "original" => "https://image.tmdb.org/t/p/original/qJ2tW6WMUDux911r6m7haRef0WH.jpg"
    },
    "tagline" => "Welcome to a world without rules."}
  }
end

  def create_response_hash(response)
    JSON.parse(response)
  end

  def create_omdb_request(movie_name)
    formatted_movie_name = movie_name.gsub(" ", '+')
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
    create_recomedation(create_response_hash(response), query.id)
  end

  def create_more_like_this_openai_request(query)
    mood = MOOD[@query.happiness]
    response = OpenaiService.new(create_more_like_this_prompt(query, mood)).call
    create_recomedation(create_response_hash(response), query.id)
  end
end
