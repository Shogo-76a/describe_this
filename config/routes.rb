Rails.application.routes.draw do
  get "locales/update"

  # 言語設定
  resource :locale, only: [ :update ]

  # 音声認識
  resources :transcriptions, only: [ :new, :create ]

  # ドキュメント
  get "documents/privacy_policy"
  get "documents/terms"

  # 管理画面
  mount Avo::Engine, at: Avo.configuration.root_path

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
  root "guest/games#top"
  namespace :guest do
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
  resources :users, only: [ :show ] do
    member do
      get :top
    end
    resources :games, only: [ :index, :new, :create, :show, :update, :destroy ] do
      member do
        get :score
        get :feedback
        get :check_generated_image
        get :check_score
      end
    end
  end
end
