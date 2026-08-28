require 'rails_helper'

RSpec.describe 'プレイ履歴ページ', type: :system do
  # ゲーム開始から画像生成・更新までの一連を1カセットにまとめる想定

  let(:user) { create(:user) }
  before do
    sign_in(user) # 共通化した登録処理を呼び出し
    find('.modal').send_keys(:escape) # ポップアップを消す
  end

  context '履歴が ない場合' do
    it '要素が正しく表示される', js: true do
      visit user_games_path(user.id)
      expect(page).to have_field(placeholder: '🔍ワード検索', with: @query)
      expect(page).to have_content("プレイ履歴がありません。")
    end
  end

  context '履歴が ある場合' do
    let!(:game) { create(:game, :with_generated_image, :with_feedback, user_id: user.id, ) }
    it '要素が正しく表示される', js: true do
      visit user_games_path(user.id)
      expect(page).to have_field(placeholder: '🔍ワード検索', with: @query)
      expect(page).to have_content("Cloud-Capped Peaks") # gameのテストデータにある履歴用タイトル
    end
  end
end
