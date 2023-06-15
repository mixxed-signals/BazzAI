Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  get '/search', to: 'recommendations#search'
  post '/search', to: 'recommendations#create'

  get '/search/:id/recommendations', to: 'recommendations#index', as: 'search_result'
  get '/search/:id/recommendations/:id', to: 'recommendations#show', as: 'search_result_details'
  delete '/search/:search_id/recommendations/:id/delete', to: 'recommendations#destroy', as: 'destroy_recommendation'
  post '/search/:id/recommendations/:id', to: 'recommendations#add_recommendations', as: 'add_recommendations_to_watch_list'

  get '/user', to: 'pages#user_page', as: 'watchlist'
end
