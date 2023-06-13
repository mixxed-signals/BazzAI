class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def user_page
    @user = current_user
    @querys = Query.where(user: current_user)
    @recommendations = Recommendation.where(query: @querys)
  end
end
