require 'rails_helper'

RSpec.describe '利用規約ページ (Terms of Service)', type: :system do
  before do
    # 利用規約ページへ遷移
    visit terms_user_path(9999)
    page.refresh # 導入画面をスキップする
  end

  describe '画面表示の確認' do
    it '「利用規約」が表示されていること' do
      expect(page).to have_content('利用規約')
    end

    it '各セクションの見出しが正しく表示されていること' do
      expect(page).to have_content('1. 利用規約への同意')
      expect(page).to have_content('2. 機能および外部AIの利用について')
      expect(page).to have_content('3. アカウント管理および責任')
      expect(page).to have_content('4. 禁止事項')
      expect(page).to have_content('5. ユーザーコンテンツと知的財産権')
      expect(page).to have_content('6. 免責事項・アカウント停止')
      expect(page).to have_content('7. サービスの変更・規約の変更')
      expect(page).to have_content('8. 準拠法および管轄裁判所')
    end

    it '重要な規約内容（免責事項など）のテキストが含まれていること' do
      # 同意の文章
      expect(page).to have_content('「Describe This」（以下「本アプリ」）をご利用いただくことで、ユーザーは本利用規約およびプライバシーポリシーに同意したものとみなします。')

      # AIに関する免責事項
      expect(page).to have_content('AIが生成・出力する内容は、必ずしも正確性、完全性、または有用性を保証するものではありません。')

      # 最終更新日の記載
      expect(page).to have_content('最終更新日：')
    end
  end
end
