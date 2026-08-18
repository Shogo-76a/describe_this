Rails.application.config.middleware.use OmniAuth::Builder do
  # Googleの設定
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
    scope: "email, profile",
    prompt: "select_account"
  }

  # LINEの設定
  provider :line_v2_1, ENV["LINE_CHANNEL_ID"], ENV["LINE_CHANNEL_SECRET"], {
    scope: "profile openid email",
    open_in_browser: false
  }

  # X (Twitter OAuth 2.0) の設定
  provider :twitter2, ENV["X_CLIENT_ID"], ENV["X_CLIENT_SECRET"], {
    scope: "users.read tweet.read users.email"
  }
end

# Railsのセッション管理とOmniAuthの競合を防ぐための設定
OmniAuth.config.allowed_request_methods = [:post]