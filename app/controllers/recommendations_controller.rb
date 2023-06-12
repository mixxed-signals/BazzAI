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
    "Hey Bazzy! Can you recommend me #{query.medium}?\n" \
    "I only have around #{query.time} minutes to spare, and I'll be watching this movie as \"#{query.audience}\"\n" \
    "The genres I'm in the mood for are: #{query.genre}. And I'm willing to focus on a level of #{query.intensity}/10.\n" \
    "My general mood right now could be described as \"#{mood}\", and I'm feeling like watching something experimental on a level of #{query.novelty}/10.\n" \
    "By the way, I enjoyed these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}.\n" \
    "Also, this is a bit more information about myself and my day: #{query.other}."
  end

  def create_more_like_this_prompt(query)
    my_prompt = "Can you recommend me 3 more #{query.medium} like #{recommendation.movie_name}?"
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
