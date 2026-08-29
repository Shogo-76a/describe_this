module LoginSupport
  def sign_in(user)
    visit new_session_path # ログインページのパス
    page.refresh # 導入画面をスキップ
    fill_in "email_address", with: user.email_address
    fill_in "password", with: user.password
    click_button "ログイン"
    expect(page).to have_current_path(top_user_path(user.id), ignore_query: true) # トップページへの遷移を待つ場合
  end
end
