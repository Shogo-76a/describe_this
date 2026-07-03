Rails.application.routes.draw do
  mount_avo
  root "games#top"

  resources :games, only: [ :new, :create, :show, :update, :destroy ] do
    member do
      get :score
      get :feedback
      get :check_generated_image
    end
  end
  resources :users, only: [ :show ]
end
