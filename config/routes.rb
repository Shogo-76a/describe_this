Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root "games#top"

  resources :games, only: [:create, :show]
end
