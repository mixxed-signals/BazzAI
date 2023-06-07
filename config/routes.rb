Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  get '/search', to: 'recommendations#search'
  post '/search', to: 'recommendations#create'
  get '/search/:id', to: 'recommendations#index', as: 'search_result'
  get '/search/:id/recommendation/:id', to: 'recommendations#show', as: 'movie'

  # resources :recommendations, only: [:search, :index, :show]
end
