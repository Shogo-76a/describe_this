Rails.application.routes.draw do
  mount_avo
  root "games#top"

  resources :games, only: [ :new, :create, :show, :edit, :update, :destroy ]
  resources :users, only: [ :show ]
end
