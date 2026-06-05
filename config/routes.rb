Rails.application.routes.draw do
  mount_avo
  root "games#top"

  get "tutorial_step", to: "games#tutorial_step"

  resources :games, only: [ :create, :show ]
end
