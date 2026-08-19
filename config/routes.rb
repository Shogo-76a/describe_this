Rails.application.routes.draw do
  # ドキュメント
  get "documents/privacy_policy"
  get "documents/terms"

  # 管理画面
  mount_avo

  # 認証関連

  # OmniAuth 専用のコールバックURL
  get "/auth/:provider/callback", to: "omniauth_callbacks#create"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  get "registrations/new"
  post "registrations/create"
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [ :new, :create ] # ユーザー登録画面

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

  # 認証ルート
  root "games#top"
  resources :games, only: [ :new, :create, :show, :update, :destroy ] do
    member do
      get :top
      get :score
      get :feedback
      get :check_generated_image
      get :check_score
    end
  end

  resources :users, only: [ :show ]
end
