Rails.application.routes.draw do
  mount_avo
  root "games#top"

  resources :games, only: [ :new, :create, :show, :update, :destroy ] do
    member do
      # 採点/フィードバックのアクションを追加定義
      get :score 
      get :feedback
    end
  end
  resources :users, only: [ :show ]
end
