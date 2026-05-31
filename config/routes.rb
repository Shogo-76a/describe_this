Rails.application.routes.draw do
  mount_avo
  root "games#top"

  resources :games, only: [ :create, :show ]
end
