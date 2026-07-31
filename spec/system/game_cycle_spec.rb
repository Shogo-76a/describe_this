require 'rails_helper'

RSpec.describe 'ゲームメインサイクル', type: :system do
  let(:user) { create(:user) }

  # ゲーム開始から画像生成・更新までの一連を1カセットにまとめる想定
  it '開始画面から画面3のAPIデータ変換・更新まで一連の流れが正しく機能すること', vcr: { cassette_name: 'game_cycle_flow' }, js: true do
    # --- ゲーム開始画面 ---
    visit new_game_path
    page.refresh # 導入画面をスキップする
    # `はじめる` → new に遷移するアプリ構成なら root からの遷移を書く
    # このテストは new_game_path を直接叩く想定
    expect(page).to have_content("お題")
    expect(page).to have_button("つぎへ")

    click_button 'つぎへ' # new -> create/show 等の遷移をトリガ
    expect(page).to have_css('img')

    # --- 画像生成ページで説明文を入力して送信（update に相当） ---
    expect(page).to have_button("お題を 英語で 説明してください", disabled: true)
    fill_in 'game_description', with: 'a coffee cup on a table'
    find('button.btn-primary.d-inline-flex').click # 送信ボタン
    expect(page).to have_css('button[data-chat-form-target="submitButton"][disabled]')

    # 送信後、採点ボタンが有効になることを確認（画像生成/ジョブ結果をVCRで再生）
    expect(page).to have_button("採点", disabled: false, wait: 60)
  end

  # 採点ページ と フィードバックページ の表示確認（生成済み画像ありのダミーゲームを使用）
  let(:game_dummy) { create(:game, :with_generated_image) }
  it "採点ページ と フィードバックページ の要素が 表示される", vcr: { cassette_name: 'game_cycle_feedback' }, js: true do
    visit score_game_path(game_dummy)
    page.refresh # 導入画面をスキップする
    expect(page).to have_content("採点結果")
    expect(page).to have_content("イメージ")
    expect(page).to have_content("シンクロ率")
    expect(page).to have_selector('.radial-progress', visible: true)
    expect(page).to have_button("つぎへ")

    visit feedback_game_path(game_dummy)
    expect(page).to have_content("フィードバック")
    expect(page).to have_css('span.loading.loading-dots.loading-sm')
    expect(page).to have_content("総評", wait: 5)
    expect(page).to have_content("スペルミス")
    expect(page).to have_content("自然な言い回し")
    expect(page).to have_content("関連フレーズ")
    expect(page).to have_content("まとめ")
    expect(page).to have_link("リトライ")
    expect(page).to have_button("やめる")
  end
end