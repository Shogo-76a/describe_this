require 'rails_helper'


RSpec.describe "画面表示物 の確認", type: :system do
  context "初回アクセス", js: true do
    it "導入画面 が表示される" do
      # このテストはJavaScriptが必要なことが明確
      visit root_path
      expect(page).to have_css(
        'div.bg-primary.mx-auto.h-24.w-24.object-contain',
        style: { 'mask-image' => /DT_logo/ }
      )
    end

    it "ポップアップ が表示される /「とじる」ボタンで ポップアップ が非表示になる" do
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

    it "トップページ の要素が すべて 表示される" do
      # このテストはJavaScriptを必要としないことが明確

      # 確認したいトップページテキストのリスト
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
      expect(page).to have_link("プロフィール", href: user_path(9999)) # MVP用仮プロフィールページのパス
    end
  end

  context "ブラウザ を リロード", js: true do
    before do
      visit root_path
      page.refresh # 1回目ページ更新
      page.refresh # 2回目ページ更新により、ポップアップが消える。(1回目ページ更新では、トップページ要素のクラスloadingが消えたことで、ポップアップ表示。)
    end

    it "導入画面が表示されない" do
      # このテストはJavaScriptが必要なことが明確
      expect(page).not_to have_css(
        'div.bg-primary.mx-auto.h-24.w-24.object-contain',
        style: { 'mask-image' => /DT_logo/ }
      )
    end

    it "ポップアップ が表示されない" do
      expect(page).not_to have_css(".modal", visible: true)
      expect(page).not_to have_content("① 見たままを英語にする")
    end

    it "トップページ の要素が すべて 表示される" do
      # このテストはJavaScriptを必要としないことが明確
      # 確認したいテキストのリスト
      expected_texts = [
        "英語 学習に遊びを",
        "あなたの 英語 で",
        "AIがお題のイメージを想像",
        "正確に伝わるかな？",
        "知ってる語彙や文法を出し切って",
        "新たな表現と出会う旅へ"
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
      expect(page).to have_link("プロフィール", href: user_path(9999)) # MVP用仮プロフィールページのパス
    end

    it "プロフィールページの要素が すべて 表示される" do
      visit user_path(9999) # MVP用仮プロフィールページのパス
      expect(page).to have_content("ドキュメント")
      expect(page).to have_content("利用規約")
      expect(page).to have_content("プライバシーポリシー")
    end

    it "ゲーム導入ページの要素が すべて 表示される" do
      visit new_game_path
      expect(page).to have_content("お題")
      expect(page).to have_content("このイメージを 英語 で伝えてください。")
      expect(page).to have_css('img')
      expect(page).to have_css('button[onclick="window.location.reload();"] svg')
      expect(page).to have_button("つぎへ")
    end

    it "画像生成ページの要素が すべて 表示される", vcr: true do
      visit new_game_path
      click_button 'つぎへ'
      expect(page).to have_css('img')
      expect(page).to have_button("お題を 英語で 説明してください", disabled: true)
      expect(page).to have_css('svg.size-6 path[d^="M6 12"]') # 送信ボタン

      fill_in 'game_description', with: '机の上のコーヒーカップとノートパソコン。' # VCRのカセット使用条件に影響。
      find('button.btn-primary.d-inline-flex').click # 送信ボタン
      expect(page).to have_css('button[data-chat-form-target="submitButton"][disabled]') # 送信ボタンの非アクティブを確認
      expect(page).to have_css(
        'button[data-collapsible-image-target="submitButton"]:disabled span.loading-spinner', wait: 10 # 採点ボタンのローディング表示
      ) # 採点ボタンのローディング表示

      expect(page).to have_button("採点", disabled: false, wait: 60)
      expect(page).not_to have_button('採点', disabled: true) # 採点ボタンが確実に無効状態でなくなった事を確認。
    end

    # 採点ページのテスト用ダミーデータ
    let(:game_dummy) { create(:game, :with_generated_image) }
    it "採点ページの要素が 表示される", vcr: true do
      visit score_game_path(game_dummy)
      expect(page).to have_content("採点結果")
      expect(page).to have_content("イメージ")
      expect(page).to have_content("シンクロ率")
      expect(page).to have_selector('.radial-progress', visible: true)
      expect(page).to have_button("つぎへ")
    end
  end
end
