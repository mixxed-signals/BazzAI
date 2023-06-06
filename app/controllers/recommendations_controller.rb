class RecommendationsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[search index show]

  def search
  end

  def index
  end

  def show
  end
end
