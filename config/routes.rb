Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  get '/search', to: 'recommendations#search'
  post '/search', to: 'recommendations#create'

  get '/search/:id/recommendations', to: 'recommendations#index', as: 'search_result'
  get '/search/:id/recommendations/:id', to: 'recommendations#show', as: 'search_result_details'
  delete '/search/:id/recommendations/:id', to: 'recommendations#destroy', as: 'delete_recommendation'

  get '/userpage', to: 'pages#user_page', as: 'watchlist'

  post '/watch_lists/:id/add_recommendations', to: 'watch_lists#add_recommendations', as: 'add_recommendations_to_watch_list'
end
