require 'rails_helper'
require 'webmock/rspec'

RSpec.describe RecommendationsController, type: :controller do
  before do
    OpenAI.configure do |config|
      config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
      config.request_timeout = 240 # Optional
    end
  end

  describe '#create_openai_request' do
    let(:query) { create(:query) } # Create a query object using FactoryBot or any other method that suits your project

    it 'creates recommendations based on OpenAI API response' do
      mood = 'Happy' # Set the mood for the test case
      openai_response = 'Lion King. The Godfather. The Shawshank Redemption.'

      # Stub the HTTP request to the OpenAI API using WebMock
      stub_request(:post, 'https://api.openai.com/v1/engines/davinci-codex/completions')
        .to_return(status: 200, body: { "choices" => [{ "message" => { "content" => openai_response } }] }.to_json)

      # Expect the create_recomedation method to be called with the correct arguments
      expected_movies = ['Lion King', 'The Godfather', 'The Shawshank Redemption']
      expect(controller).to receive(:create_recomedation).with(expected_movies, query.id)

      # Call the method under test
      response = controller.create_openai_request(query)
      movies = create_response_arr(response)
      expect(movies).to eq(expected_movies)
    end

    def create_response_arr(response)
      response.gsub(/(\A[\d.,]+|\n)/, '').split('. ').map { |movie| movie.gsub(/\A[\d.,]+/, '').strip }
    end
  end
end
