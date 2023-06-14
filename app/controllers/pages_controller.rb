class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def user_page
    @user = current_user
    @querys = Query.where(user: current_user)

    @recommendations = Recommendation.where(query: @querys)
    @watch_list_movies = WatchList.where(user: current_user)
    @watch_list = RecommendationWatchList.where(watch_list: @watch_list_movies)
    @watch_list = @watch_list.map { |watch_list| watch_list.recommendation }
  end
end
