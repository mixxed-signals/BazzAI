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
  end

  def show
    @recommendation = Recommendation.find(params[:id])
    get_streaming_availability(@recommendation.imdbID)
  end

  private

  def query_params
    selected_genres = params[:query][:genre].reject { |_, value| value == "0" }.keys.join(", ")
    selected_medium = params[:query][:medium].reject { |_, value| value == "0" }.keys.join(", ")
    selected_audience = params[:query][:audience].reject { |_, value| value == "0" }.keys.join(", ")
    params.require(:query).permit(:user_id, :time, :year_after, :year_before, :year_option, :happiness, :intensity, :novelty, :recent_movie1, :recent_movie2, :recent_movie3, :other).merge(medium: selected_medium, audience: selected_audience, genre: selected_genres)
  end

  def create_prompt(query, mood)
    request_part = "Show me a list of 10 real #{query.medium}, just the titles in a string separated by a dot and a space '. ', and never put the #{query.medium} year or episode, use this information about me:"

    movie_time = "Movie time: #{query.time} minutes." if query.time.present?
    movie_genre = "Genres: #{query.genre}." if query.genre.present?
    movie_mood = "I want a movie that makes me feel: #{mood}." if mood.present?
    movie_audience = "I'm going to watch this movie as: #{query.audience}." if query.audience.present?
    movie_concentrate = "Level of concentration I need to watch the movie: #{query.intensity}/10." if query.intensity.present?
    movie_novelty = "I want the movie to be experimental and non-mainstream on a level: #{query.novelty}/10." if query.novelty.present?
    recent_movies = "I watched these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3} and I enjoyed them. Take them into account but don't suggest them to me again." if query.recent_movie1.present? || query.recent_movie2.present? || query.recent_movie3.present?
    other = "Other information about myself and my day to filter this movie: #{query.other}." if query.other.present?

    separate_part = "Separate the movies with a dot and a space '. '."

    return "#{request_part}\n#{movie_time}\n#{movie_genre}\n#{movie_mood}\n#{movie_audience}\n#{movie_concentrate}\n#{movie_novelty}\n#{recent_movies}\n#{other}\n#{separate_part}"
  end

  def create_display_prompt(query, mood)
    my_prompt = "Hey Bazzy! Can you recommend me #{query.medium}? \ \n
    I only have around #{query.time} minutes to spare, and I'll be watching this movie as \"#{query.audience}\" \n \
    The genres I'm in the mood for are: #{query.genre}. And I'm willing to focus on a level of #{query.intensity}/10. \n \
    My general mood right now could be described as \"#{mood}\", and I'm feeling like watching something experimental on a level of #{query.novelty}/10. \n \
    By the way, I enjoyed these movies recently: #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}. \n \
    Also, this is a bit more information about myself and my day: #{query.other}."
    return my_prompt
  end

  def create_recomedation(response, query)
    movies = response.map do |movie_name|
      data = create_omdb_request(movie_name)
      break if data['Response'] == 'False'

      recommendation = create_recomedation_class(movie_name, data, query)
      recommendation.save
    end
    return movies
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
    return nil if data['trailer'].nil?

    "https://www.youtube.com/embed/#{data['trailer']['youtube_video_id']}"
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
  @data = {"result"=>{"type"=>"movie", "title"=>"The Dark Knight", "overview"=>"Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle the remaining criminal organizations that plague the streets. The partnership proves to be effective, but they soon find themselves prey to a reign of chaos unleashed by a rising criminal mastermind known to the terrified citizens of Gotham as the Joker.", "streamingInfo"=>{"de"=>{"netflix"=>[{"type"=>"subscription", "quality"=>"hd", "addOn"=>"", "link"=>"https://www.netflix.com/title/70079583/", "watchLink"=>"https://www.netflix.com/watch/70079583", "audios"=>nil, "subtitles"=>nil, "price"=>nil, "leaving"=>0, "availableSince"=>1649233522}], "prime"=>[{"type"=>"buy", "quality"=>"hd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00K7AKZL2/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"eng", "region"=>""}], "subtitles"=>nil, "price"=>{"amount"=>"9.99", "currency"=>"EUR", "formatted"=>"9.99 EUR"}, "leaving"=>0, "availableSince"=>1675657411}, {"type"=>"buy", "quality"=>"sd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00K7AKZL2/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"eng", "region"=>""}], "subtitles"=>nil, "price"=>{"amount"=>"9.99", "currency"=>"EUR", "formatted"=>"9.99 EUR"}, "leaving"=>0, "availableSince"=>1675657411}, {"type"=>"rent", "quality"=>"hd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00K7AKZL2/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"eng", "region"=>""}], "subtitles"=>nil, "price"=>{"amount"=>"3.99", "currency"=>"EUR", "formatted"=>"3.99 EUR"}, "leaving"=>0, "availableSince"=>1675657411}, {"type"=>"rent", "quality"=>"sd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00G0OFW9O/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"deu", "region"=>""}, {"language"=>"eng", "region"=>""}], "subtitles"=>[{"locale"=>{"language"=>"deu", "region"=>""}, "closedCaptions"=>false}, {"locale"=>{"language"=>"eng", "region"=>""}, "closedCaptions"=>true}], "price"=>{"amount"=>"3.99", "currency"=>"EUR", "formatted"=>"3.99 EUR"}, "leaving"=>0, "availableSince"=>1675657541}, {"type"=>"buy", "quality"=>"sd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00G0OFW9O/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"deu", "region"=>""}, {"language"=>"eng", "region"=>""}], "subtitles"=>[{"locale"=>{"language"=>"deu", "region"=>""}, "closedCaptions"=>false}, {"locale"=>{"language"=>"eng", "region"=>""}, "closedCaptions"=>true}], "price"=>{"amount"=>"9.99", "currency"=>"EUR", "formatted"=>"9.99 EUR"}, "leaving"=>0, "availableSince"=>1675657541}, {"type"=>"rent", "quality"=>"sd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00K7AKZL2/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"eng", "region"=>""}], "subtitles"=>nil, "price"=>{"amount"=>"3.99", "currency"=>"EUR", "formatted"=>"3.99 EUR"}, "leaving"=>0, "availableSince"=>1675657411}, {"type"=>"rent", "quality"=>"hd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00G0OFW9O/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"deu", "region"=>""}, {"language"=>"eng", "region"=>""}], "subtitles"=>[{"locale"=>{"language"=>"deu", "region"=>""}, "closedCaptions"=>false}, {"locale"=>{"language"=>"eng", "region"=>""}, "closedCaptions"=>true}], "price"=>{"amount"=>"3.99", "currency"=>"EUR", "formatted"=>"3.99 EUR"}, "leaving"=>0, "availableSince"=>1675657541}, {"type"=>"buy", "quality"=>"hd", "addOn"=>"", "link"=>"https://www.amazon.de/gp/video/detail/B00G0OFW9O/ref=atv_dp?language=en", "watchLink"=>"", "audios"=>[{"language"=>"deu", "region"=>""}, {"language"=>"eng", "region"=>""}], "subtitles"=>[{"locale"=>{"language"=>"deu", "region"=>""}, "closedCaptions"=>false}, {"locale"=>{"language"=>"eng", "region"=>""}, "closedCaptions"=>true}], "price"=>{"amount"=>"9.99", "currency"=>"EUR", "formatted"=>"9.99 EUR"}, "leaving"=>0, "availableSince"=>1675657541}]}}, "cast"=>["Christian Bale", "Heath Ledger", "Michael Caine", "Gary Oldman", "Aaron Eckhart", "Maggie Gyllenhaal", "Morgan Freeman"], "year"=>2008, "advisedMinimumAudienceAge"=>12, "imdbId"=>"tt0468569", "imdbRating"=>90, "imdbVoteCount"=>2714996, "tmdbId"=>155, "tmdbRating"=>85, "originalTitle"=>"The Dark Knight", "backdropPath"=>"/dqK9Hag1054tghRQSqLSfrkvQnA.jpg", "backdropURLs"=>{"1280"=>"https://image.tmdb.org/t/p/w1280/dqK9Hag1054tghRQSqLSfrkvQnA.jpg", "300"=>"https://image.tmdb.org/t/p/w300/dqK9Hag1054tghRQSqLSfrkvQnA.jpg", "780"=>"https://image.tmdb.org/t/p/w780/dqK9Hag1054tghRQSqLSfrkvQnA.jpg", "original"=>"https://image.tmdb.org/t/p/original/dqK9Hag1054tghRQSqLSfrkvQnA.jpg"}, "genres"=>[{"id"=>28, "name"=>"Action"}, {"id"=>80, "name"=>"Crime"}, {"id"=>18, "name"=>"Drama"}], "originalLanguage"=>"en", "countries"=>["GB", "US"], "directors"=>["Christopher Nolan"], "runtime"=>152, "youtubeTrailerVideoId"=>"kmJLuwP3MbY", "youtubeTrailerVideoLink"=>"https://www.youtube.com/watch?v=kmJLuwP3MbY", "posterPath"=>"/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "posterURLs"=>{"154"=>"https://image.tmdb.org/t/p/w154/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "185"=>"https://image.tmdb.org/t/p/w185/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "342"=>"https://image.tmdb.org/t/p/w342/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "500"=>"https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "780"=>"https://image.tmdb.org/t/p/w780/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "92"=>"https://image.tmdb.org/t/p/w92/qJ2tW6WMUDux911r6m7haRef0WH.jpg", "original"=>"https://image.tmdb.org/t/p/original/qJ2tW6WMUDux911r6m7haRef0WH.jpg"}, "tagline"=>"Welcome to a world without rules."}}
end


  def create_response_arr(response)
    response = response.gsub(/\.\d+/, '')
    response = response.gsub(/(\.\d+|\n)/, '')
    response = response.split(". ")
    return response
  end

def create_omdb_request(movie_name)
  formatted_movie_name = movie_name.gsub(' ', '+')
  url = "http://www.omdbapi.com/?t=#{formatted_movie_name}&apikey=#{OMDB_API_KEY}"
  uri = URI(url)
  response = Net::HTTP.get(uri)
  return JSON.parse(response)
end

  def create_openai_request(query)
    mood = MOOD[@query.happiness]
    # prompt = create_prompt(query, mood)
    # response = 'Lion King. The Godfather. The Shawshank Redemption. The Dark Knight. Pulp Fiction. Schindler\'s List'
    response = OpenaiService.new(create_prompt(query, mood)).call
    create_recomedation(create_response_arr(response), query.id)
  end
end
