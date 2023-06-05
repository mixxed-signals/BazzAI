class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    # @response = OpenaiService.new('Hey GPT').call
  end
end
