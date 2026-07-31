require 'rails_helper'

RSpec.describe '導入ポップアップ', type: :system, js: true do
  it 'ポップアップ が表示される / 「とじる」ボタンで ポップアップ が非表示になる' do
    visit root_path
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