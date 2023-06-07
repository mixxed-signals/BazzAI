Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  devise_for :users
  root to: "pages#home"
  get 'recommendations/search'
  post '/recommendations', to: 'recommendations#create', as: 'recommendations'
  resources :recommendations, only: %i[search index show]
end
