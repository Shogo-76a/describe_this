class UsersController < ApplicationController
  # allow_unauthenticated_access 全アクションで認証無効化

    def show
      # プロフィールページ
      # MVP では仮ページを表示
      # 本リリース ではユーザーテーブルからユーザーIDを渡す
    end

    def privacy_policy; end
    def terms; end
end
