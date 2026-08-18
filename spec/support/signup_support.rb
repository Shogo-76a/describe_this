module SignupSupport
  def sign_up(user)
    visit registrations_new_path # 登録ページのパス
    page.refresh # 導入画面をスキップ
    fill_in "ユーザー名", with: user.name
    fill_in "メールアドレス", with: user.email_address
    fill_in "パスワード", with: user.password
    fill_in "パスワード（確認用）", with: user.password
    click_button "登録する"
  end
end
