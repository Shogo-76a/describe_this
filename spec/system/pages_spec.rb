require 'rails_helper'


RSpec.describe "画面表示物の確認", type: :system do
  context "初回アクセス時（スプラッシュ画面あり）", js: true do
    it "導入画面が表示される" do
      # このテストはJavaScriptが必要なことが明確
      visit root_path
      expect(page).to have_selector("img[src*='DT_logo'][alt='ロゴ']")
    end

    it "トップページの要素がすべて表示される" do
      # このテストはJavaScriptを必要としないことが明確

      # 確認したいテキストのリスト
      expected_texts = [
        "説明する練習が楽しく続く",
        "あなたの言葉で",
        "AIがお題のイメージを想像",
        "正確に伝えられるかな？",
        "「伝わらない」を「伝わる」の自信に。",
        "ステキな表現を探す旅へ。"
      ]

      visit root_path
      expect(page).to have_selector("img[src*='DT_title'][alt='Describe this']", wait: 4)
      expected_texts.each do |text|
        expect(page).to have_content(text)
      end
      expect(page).to have_button("はじめる")
      expect(page).to have_link("ホーム", href: root_path)
      expect(page).to have_link("プレイ履歴", href: root_path)
      expect(page).to have_link("プロフィール", href: root_path)
    end
  end

end