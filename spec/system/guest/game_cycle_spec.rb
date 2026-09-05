require 'rails_helper'

RSpec.describe 'ゲスト ゲームメインサイクル', type: :system do
  # ゲーム開始から画像生成・更新までの一連を1カセットにまとめる想定
  context '生成画像がある場合' do
    it '開始画面から画面3のAPIデータ変換・更新まで一連の流れが正しく機能すること', vcr: { cassette_name: 'guest_game_cycle_flow' }, js: true do
      visit root_path
      page.refresh
      find('.modal').send_keys(:escape) # ポップアップを消す

      all('.dropdown.w-30')[0].click
      find('.dropdown-content.menu a', text: '英語').click
      expect(page).to have_css('.btn-sm.select', text: '英語')

      # --- ゲーム開始画面 ---
      visit new_guest_game_path
      page.refresh # 導入画面をスキップ

      expect(page).to have_content("お題")
      expect(page).to have_button("つぎへ")

      click_button 'つぎへ' # new -> create/show をトリガ
      expect(page).to have_css('img')

      # --- 画像生成ページで説明文を入力して送信（update に相当） ---
      expect(page).to have_content("お題を 英語で 説明してください")

      # 録音ボタンの要素が揃ってるか確認する。切替テストはしない。テスト環境でのマイク認証が難しい。
      expect(page).to have_css('.btn[data-transcription-target="recordButton"]')
      expect(page).to have_css('.btn[data-transcription-target="stopButton"]', visible: false)
      expect(page).to have_css('.btn[data-transcription-target="loadButton"]', visible: false)

      find('textarea[name="game[description]"]').set('a coffe cup on a tablu and the warm soft light is spot these items through a window in front of the table.') # スペルミスを意図的に含む coffe:coffee, tablu:table
      find('button.btn-primary.d-inline-flex').click # 送信ボタン
      expect(page).to have_css('button[data-guest--chat-form-target="sendButton"][disabled]')

      # 送信後、採点ボタンが有効になることを確認（画像生成/ジョブ結果をVCRで再生）
      expect(page).to have_button("採点", disabled: false, wait: 60)
      click_button '採点' # show -> score の遷移をトリガ

      # --- 採点ページ ---
      expect(page).to have_content("採点結果", wait: 60)
      expect(page).to have_content("イメージ")
      expect(page).to have_content("シンクロ率")
      expect(page).to have_selector('.radial-progress', visible: true) # スコア
      expect(page).to have_css('[data-evaluation-target="text"]') # 評価テキスト
      expect(page).to have_content("評価基準について")
      click_button '評価基準について'

      # モーダルを確認
      expect(page).to have_css(".modal", visible: true)
      expect(page).to have_content("Great（とても良い）")
      find('.modal').send_keys(:escape) # モーダルを消す

      expect(page).to have_button("つぎへ")
      click_button 'つぎへ' # score -> feedback の遷移をトリガ

      # --- フィードバックページ ---
      expect(page).to have_content("フィードバック")
      expect(page).to have_link("リトライ")
      expect(page).to have_button("やめる")
    end
  end
end
