Rails.application.routes.draw do
  root "games#top"

  resources :games, only: [:create, :show]
end
