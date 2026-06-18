require 'rails_helper'


RSpec.describe "画面表示物 の確認", type: :system do
  context "初回アクセス", js: true do
    it "導入画面 が表示される" do
      # このテストはJavaScriptが必要なことが明確
      visit root_path
      expect(page).to have_selector("img[src*='DT_logo'][alt='ロゴ']")
    end

    it "ポップアップ が表示される /「とじる」ボタンで ポップアップ が非表示になる" do
      visit root_path
      expect(page).to have_css(".modal", visible: true, wait: 4)
      expect(page).to have_content("① 見たままを言葉にする")
      click_button 'つぎへ'
      expect(page).to have_content("② AIがイメージして採点")
      click_button 'つぎへ'
      expect(page).to have_content("③ コツを学んでレベルUP")
      click_button 'とじる'
      expect(page).not_to have_css(".modal", visible: true)
    end

    it "トップページ の要素が すべて 表示される" do
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
      expect(page).to have_link("プレイ履歴", href: "#")
      expect(page).to have_link("プロフィール", href: user_path(9999)) # MVP用仮プロフィールページのパス
    end
  end

  context "ブラウザ を リロード", js: true do
    before do
      visit root_path
      page.refresh     # 1回目ページ更新
    end
    it "導入画面が表示されない" do
      # このテストはJavaScriptが必要なことが明確
      expect(page).not_to have_selector("img[src*='DT_logo'][alt='ロゴ']")
    end

    it "ポップアップ が表示されない" do
      visit root_path
      page.refresh # 2回目ページ更新により、ポップアップが消える。(1回目ページ更新では、トップページ要素のクラスloadingが消えたことで、ポップアップ表示。)
      expect(page).not_to have_css(".modal", visible: true)
      expect(page).not_to have_content("① 見たままを言葉にする")
    end

    it "トップページ の要素が すべて 表示される" do
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
      expect(page).to have_selector("img[src*='DT_title'][alt='Describe this']")
      expected_texts.each do |text|
        expect(page).to have_content(text)
      end
      expect(page).to have_button("はじめる")
      expect(page).to have_link("ホーム", href: root_path)
      expect(page).to have_link("プレイ履歴", href: "#")
      expect(page).to have_link("プロフィール", href: user_path(9999)) # MVP用仮プロフィールページのパス
    end

    it "プロフィールページの要素が すべて 表示される" do
      visit user_path(9999) # MVP用仮プロフィールページのパス
      expect(page).to have_content("ドキュメント")
      expect(page).to have_content("利用規約")
      expect(page).to have_content("プライバシーポリシー")
    end

    it "ゲーム導入ページの要素が すべて 表示される" do
      visit new_game_path # MVP用仮プロフィールページのパス
      expect(page).to have_content("お題")
      expect(page).to have_content("このイメージを言葉で伝えてください。")
      expect(page).to have_css('button[onclick="window.location.reload();"] svg')
      expect(page).to have_button("つぎへ")
      expect(page).to have_css('img')
    end
  end
end
