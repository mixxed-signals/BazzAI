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
      prompt += "Since you're a bit short on time, I've got some shorter #{query.medium.downcase}s lined up for you.\n" if query.time.present? && query.time < 90 && query.medium == "Movie"
      prompt += "Since you have plenty of time on your hands, I've picked out some longer #{query.medium.downcase}s for you.\n" if query.time.present? && query.time > 90 && query.medium == "Movie"
      prompt += "I've tried my best to find #{query.medium.downcase}s that you can enjoy together with your partner.\n" if query.audience == "Couple"
      prompt += "I've tried my best to find #{query.medium.downcase}s that you can enjoy with your whole family.\n" if query.audience == "Family"
      prompt += "I've tried my best to find #{query.medium.downcase}s that you can enjoy all by yourself.\n" if query.audience == "Just me"
      prompt += "You're in the mood for #{query.genre.downcase} and I get the sense that you're feeling #{mood.downcase}.\n" if query.genre.present? && mood.present?
      prompt += "I've discovered some more experimental #{query.medium.downcase}s that might satisfy your craving for novelty.\n" if query.novelty.present? && query.novelty > 7
      prompt += "Some of the #{query.medium.downcase}s I choose for you share some similarities with #{query.recent_movie1}, #{query.recent_movie2}, #{query.recent_movie3}.\n" if query.recent_movie1.present? || query.recent_movie2.present? || query.recent_movie3.present?
      prompt += "Enjoy your #{query.medium.downcase} and let me know how you liked my recommendations!\n"
    end
    return querys
  end
end
