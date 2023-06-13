Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  get '/search', to: 'recommendations#search'
  post '/search', to: 'recommendations#create'

  get '/search/:id/recommendations', to: 'recommendations#index', as: 'search_result'
  get '/search/:id/recommendations/:id', to: 'recommendations#show', as: 'search_result_details'

  require "sidekiq/web"
  mount Sidekiq::Web => '/sidekiq'
  # resources :recommendations, only: [:search, :index, :show]
end
