require 'rails_helper'

RSpec.describe 'ログイン後', type: :system do
  let(:user) { FactoryBot.create(:user) }
  before do
    sign_in(user) # 共通化した登録処理を呼び出し
    find('.modal').send_keys(:escape) # ポップアップを消す
  end

  it 'プロフィールページの要素が すべて 表示される' do
    visit user_path(user.id)
    expect(page).to have_content("利用規約")
    expect(page).to have_content("プライバシーポリシー")
    expect(page).to have_content("お問い合わせ")
  end
end
