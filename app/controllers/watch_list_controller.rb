class WatchListController < ApplicationController
  def create
    WatchList.new(user: current_user)

  end

  def add_recommendations
    @watch_list = WatchList.find_by_id(1)
    @watch_list = create if @watch_list.nil?
    @watch_list.user = current_user

    @recommendation = Recommendation.where(id: params[:recommendation_id])
    raise
    @watch_list.recommendation << @recommendation
    @watch_list.save
  end
end
