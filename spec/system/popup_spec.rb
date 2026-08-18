require 'rails_helper'

RSpec.describe 'ログイン後 導入ポップアップ', type: :system, js: true do
  let(:user) { FactoryBot.create(:user) }
  before do
    sign_in(user) # 共通化した登録処理を呼び出し
  end

  it 'ポップアップ が表示される / 「とじる」ボタンで ポップアップ が非表示になる' do
    expect(page).to have_css(".modal", visible: true, wait: 4)
    expect(page).to have_content("① 見たままを英語にする")
    click_button 'つぎへ'
    expect(page).to have_content("② AIがイメージして採点")
    click_button 'つぎへ'
    expect(page).to have_content("③ コツを学んでレベルUP")
    click_button 'とじる'
    expect(page).not_to have_css(".modal", visible: true)
  end
end
