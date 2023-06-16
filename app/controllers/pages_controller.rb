class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def user_page
    @user = current_user
    @querys = Query.where(user: current_user)

    @recommendations = Recommendation.where(query: @querys)

    @display_prompts = create_display_prompt(@querys, @mood)

    @watch_list_movies = WatchList.where(user: current_user)
    @watch_list = RecommendationWatchList.where(watch_list: @watch_list_movies)

    @watch_list = @watch_list.map { |watch_list| watch_list.recommendation }
  end

  private

  def create_display_prompt(querys, mood)
    querys = querys.map do |query|
      prompt = ""
      prompt += "Do you remember this search? Looks like you were searching for a #{query.medium.downcase} recommendation.\n" if query.medium.present?
      prompt += "Since you were a bit short on time, I gave you some shorter #{query.medium.downcase} recommendations.\n" if query.time.present? && query.time < 90 && query.medium == "Movie"
      prompt += "Since you had plenty of time on your hands, I've picked out some longer #{query.medium.downcase}s for you.\n" if query.time.present? && query.time > 90 && query.medium == "Movie"
      prompt += "I've tried my best to find #{query.medium.downcase}s that you can enjoy together with your partner.\n" if query.audience == "Couple"
      prompt += "I've tried my best to find #{query.medium.downcase}s that you can enjoy with your whole family.\n" if query.audience == "Family"
      prompt += "I've tried my best to find #{query.medium.downcase}s that you can enjoy all by yourself.\n" if query.audience == "Just me"
      prompt += "You were in the mood for #{query.genre.downcase} and I got the sense that you felt #{mood.downcase}.\n" if query.genre.present? && mood.present?
      prompt += "I discovered some more experimental #{query.medium.downcase}s that might satisfy your craving for novelty.\n" if query.novelty.present? && query.novelty > 7
      prompt += "Some of the #{query.medium.downcase}s I choose for you shared similarities with #{query.recent_movie1} and #{query.recent_movie2}.\n" if query.recent_movie1.present? && query.recent_movie2.present?
      prompt += "Some of the #{query.medium.downcase}s I choose for you shared similarities with #{query.recent_movie1}.\n" if query.recent_movie1.present? && query.recent_movie2.nil?
      prompt += "Revisit these #{query.medium.downcase}s and let me know how you liked my recommendations!\n"
    end
    return querys
  end
end
