require 'rails_helper'

RSpec.describe 'トップページ', type: :system do
  it 'トップページ の要素が すべて 表示される' do
    expected_texts = [
      "英語 学習に遊びを",
      "あなたの 英語 で",
      "AIがお題のイメージを想像",
      "正確に伝わるかな？",
      "知ってる語彙や文法を出し切って",
      "新たな表現と出会う旅へ"
    ]

    visit root_path
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
    expect(page).to have_link("プロフィール", href: user_path(9999))
  end

  it 'トップロゴのマスクが表示される（非JS）' do
    visit root_path
    expect(page).to have_css(
      'div.bg-primary.mx-auto.h-24.w-24.object-contain',
      style: { 'mask-image' => /DT_logo/ }
    )
  end
end