Rails.application.routes.draw do
  # ドキュメント
  get "documents/privacy_policy"
  get "documents/terms"

  # ゲストルート
  namespace :guest do
    root "games#top"
    resources :games, only: [ :new, :create, :show, :update, :destroy ] do
      member do
        get :score
        get :feedback
        get :check_generated_image
        get :check_score
      end
    end

    resources :users, only: [ :show ]
  end

  # 管理画面
  mount_avo

  # 認証関連
  get "registrations/new"
  get "registrations/create"
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [ :new, :create ] # ユーザー登録画面

  # 認証ルート
  root "games#top"
  resources :games, only: [ :new, :create, :show, :update, :destroy ] do
    member do
      get :score
      get :feedback
      get :check_generated_image
      get :check_score
    end
  end

  resources :users, only: [ :show ]
end
