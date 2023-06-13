class WatchListController < ApplicationController
  def create
    recommendation = Recommendation.find(params[:recommendation_id])
    watch_list = WatchList.new(user: current_user)

    if watch_list.save
      redirect_to user_path(user), notice: 'Recommendation added to watch list.'
    else
      redirect_to user_path(user), alert: 'Failed to add recommendation to watch list.'
    end
  end

  def add_recommendations
    @watch_list = WatchList.find(1)
    @recommendation = Recommendation.where(id: params[:recommendation_id])
    @watch_list.recommendations << @recommendation

    @watch_list.save
  end
end
