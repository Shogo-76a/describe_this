module RequestLoginSupport
  def sign_in(user)
    # 例：セッションコントローラーの create アクションにPOSTリクエストを送る
    post session_path, params: { name: user.name, email_address: user.email_address, password: user.password }
  end
end