Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  mount_avo
  root "games#top"

  resources :games, only: [ :new, :create, :show, :update, :destroy ] do
    member do
      get :score
      get :feedback
      get :check_generated_image
      get :check_score
    end
  end
  resources :users, only: [ :show ] do
    member do
      get :privacy_policy
      get :terms
    end
  end
end
