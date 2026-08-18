require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Line < OmniAuth::Strategies::OAuth2
      # プロバイダー名
      option :name, 'line'

      # IDトークン, プロフィール情報, メールアドレスの取得権限を含める
      option :scope, 'openid profile email'

      # LINEのAPIエンドポイント設定
      option :client_options, {
        site: 'https://api.line.me',
        authorize_url: 'https://access.line.me/oauth2/v2.1/authorize',
        token_url: 'https://api.line.me/oauth2/v2.1/token'
      }

      # LINEユーザーIDをuidとして設定
      uid { raw_info['sub'] }

      # ユーザー情報を設定
      info do
        {
          name: raw_info['name'],
          email: raw_info['email']
        }
      end

      # 追加情報（デバッグ用）
      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= verify_id_token
      end

      private

      # ID Tokenに必須のnonceをパラメータに追加
      def authorize_params
        super.tap do |params|
          params[:nonce] = SecureRandom.uuid
          session['omniauth.nonce'] = params[:nonce]
        end
      end

      # callback_urlのクエリパラメータを除去
      def callback_url
        full_host + callback_path
      end

      # ID token検証 & ユーザ情報取得
      def verify_id_token
        @id_token_payload ||= begin
          # HTTPクライアントを使用してID Token検証
          response = client.request(:post, 'https://api.line.me/oauth2/v2.1/verify', {
            body: {
              id_token: access_token['id_token'],
              client_id: options.client_id,
              nonce: session.delete('omniauth.nonce')
            }
          })
          
          response.parsed
        rescue => e
          Rails.logger.error "[LINE Login] ID token verification failed: #{e.message}"
          Rails.error.report(e, context: {
            action: '[LINE login] ID token verification & get user info',
            client_id: options.client_id,
            has_id_token: access_token['id_token'].present?
          }) if defined?(Rails.error)
          raise
        end
      end
    end
  end
end
