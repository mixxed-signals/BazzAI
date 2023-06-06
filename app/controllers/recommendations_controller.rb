class RecommendationsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[search index show]

  def search
    @query = Query.new
  end

  def create
  end 

  def index
  end

  def show
  end
end
