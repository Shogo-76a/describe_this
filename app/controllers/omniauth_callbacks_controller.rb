class OmniauthCallbacksController < ApplicationController
  # 未ログイン状態でもアクセスを許可する（Rails 8標準認証の機能）
  allow_unauthenticated_access only: [ :create, :failure ]

  def create
    # 外部サービスから返ってきた認証情報を取得
    auth = request.env["omniauth.auth"]
    
    # 認証情報を元にユーザーを検索、または新規作成
    user = User.from_omniauth(auth)

    if user.persisted?
      # Rails 8標準認証のセッション開始メソッド
      start_new_session_for user 
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "アカウントの登録に失敗しました"
    end
  end

  def failure
    redirect_to new_session_path, alert: "認証がキャンセルされたか、エラーが発生しました。"
  end
end
