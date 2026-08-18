require 'rails_helper'

RSpec.describe "Googleログイン", type: :request do
  before do
    # 1. テストモードを有効化
    OmniAuth.config.test_mode = true

    # 2. モックデータを作成
    mock_hash = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '123456',
      info: {
        name: 'Google太郎',
        email_address: 'google_user@example.com'
      }
    })

    # 3. コントローラーが読み込めるように、Rails環境にモックを直接セットする
    Rails.application.env_config["omniauth.auth"] = mock_hash
  end

  it "新規ユーザーが作成されること" do
    expect {
      get "/auth/google_oauth2/callback"
    }.to change(User, :count).by(1)
  end
end