require 'rails_helper'

RSpec.describe 'ログイン後 ゲームメインサイクル', type: :system do
  # ゲーム開始から画像生成・更新までの一連を1カセットにまとめる想定

  let(:user) { create(:user) }
  before do
    sign_in(user) # 共通化した登録処理を呼び出し
    find('.modal').send_keys(:escape) # ポップアップを消す
  end

  context '生成画像がある場合' do
    it '開始画面から画面3のAPIデータ変換・更新まで一連の流れが正しく機能すること', vcr: { cassette_name: 'game_cycle_flow' }, js: true do
      # --- ゲーム開始画面 ---
      visit new_game_path
      # `はじめる` → new に遷移するアプリ構成なら root からの遷移を書く
      # このテストは new_game_path を直接叩く想定
      expect(page).to have_content("お題")
      expect(page).to have_button("つぎへ")

      click_button 'つぎへ' # new -> create/show をトリガ
      expect(page).to have_css('img')

      # --- 画像生成ページで説明文を入力して送信（update に相当） ---
      expect(page).to have_content("お題を 英語で 説明してください")
      fill_in 'game_description', with: 'a coffe cup on a tablu.' # スペルミスを意図的に含む coffe:coffee, tablu:table
      find('button.btn-primary.d-inline-flex').click # 送信ボタン

      # 送信後、採点ボタンが有効になることを確認（画像生成/ジョブ結果をVCRで再生）
      expect(page).to have_button("採点", disabled: false, wait: 60)
      click_button '採点' # show -> score の遷移をトリガ

      # --- 採点ページ ---
      expect(page).to have_content("採点結果", wait: 60)
      expect(page).to have_content("イメージ")
      expect(page).to have_content("シンクロ率")
      expect(page).to have_selector('.radial-progress', visible: true)
      expect(page).to have_button("つぎへ")
      click_button 'つぎへ' # score -> feedback の遷移をトリガ

      # --- フィードバックページ ---
      expect(page).to have_content("フィードバック")
      expect(page).to have_css('span.loading.loading-dots.loading-sm')
      expect(page).to have_content("総評", wait: 5)
      expect(page).to have_content("あなたの説明")
      expect(page).to have_content("提案")
      expect(page).to have_content("フレーズ")
      expect(page).to have_link("リトライ")
      expect(page).to have_button("やめる")
    end
  end
end
