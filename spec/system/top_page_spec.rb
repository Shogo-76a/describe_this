require 'rails_helper'

RSpec.describe 'ログイン後 トップページ', type: :system do
  let(:user) { create(:user) }
  before do
    sign_in(user) # 共通化した登録処理を呼び出し
  end

  it 'トップページ の要素が すべて 表示される' do
    expected_texts = [
      "こんにちは！",
      "#{user.name} さん！"
    ]

    expect(page).to have_css(
      'div.bg-base-content.w-70.h-16',
      style: { 'mask-image' => /DT_title/ }, wait: 4
    )
    expected_texts.each do |text|
      expect(page).to have_content(text)
    end
    expect(page).to have_button("はじめる")
    expect(page).to have_link("ホーム", href: root_path)
    expect(page).to have_link("プレイ履歴", href: "#")
    expect(page).to have_link("プロフィール", href: user_path(user.id))
  end
end
