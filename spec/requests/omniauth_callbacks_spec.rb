require 'rails_helper'

RSpec.describe 'Googleログイン', type: :request do
  before do
    # 1. OmniAuthをテストモードに設定
    OmniAuth.config.test_mode = true

    # 2. モックデータの作成（emailが含まれているか確認）
    mock_hash = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '123456',
      info: {
        name: 'テストユーザー',
        email: 'user@example.com' # ← ここが nil になっていないか確認
      }
    })

    # 3. OmniAuthのデフォルトモックに設定
    OmniAuth.config.mock_auth[:google_oauth2] = mock_hash

    # 4. Request Spec用に Rails の env_config に直接セットする（★最重要）
    Rails.application.env_config['omniauth.auth'] = mock_hash
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  it 'ユーザーが作成されること' do
    expect {
      get '/auth/google_oauth2/callback'
    }.to change(User, :count).by(1)
  end
end
