require 'rails_helper'

RSpec.describe 'プライバシーポリシーページ (Privacy Policy)', type: :system do
  before do
    # 利用規約ページへ遷移
    visit privacy_policy_user_path(9999)
    page.refresh # 導入画面をスキップする
  end

  describe '画面表示の確認' do
    it 'ページタイトル（大見出し）として「プライバシーポリシー」が表示されていること' do
      expect(page).to have_content('プライバシーポリシー')
    end

    it '各セクションの見出しが正しく表示されていること' do
      expect(page).to have_content('1. 取得する情報')
      expect(page).to have_content('2. 利用目的')
      expect(page).to have_content('3. 外部サービスの利用（AIサービス等）')
      expect(page).to have_content('4. 第三者提供および外部委託')
      expect(page).to have_content('5. アクセス解析ツール')
      expect(page).to have_content('6. 安全管理')
      expect(page).to have_content('7. 個人情報の開示・訂正・削除')
      expect(page).to have_content('8. プライバシーポリシーの変更')
      expect(page).to have_content('9. お問い合わせ')
    end

    it '重要なプライバシーポリシーの内容が含まれていること' do
      # 導入文の確認
      expect(page).to have_content('「Describe This」（以下「本アプリ」）は、ユーザーの個人情報および入力データを適切に取り扱うため、以下のとおりプライバシーポリシーを定めます。')

      # 取得情報の詳細確認（一部）
      expect(page).to have_content('ユーザー入力データ')
      expect(page).to have_content(': 伝言ゲーム内で入力・送信された英文、翻訳テキスト、メッセージ内容等')

      # AIサービス利用に関する記述の確認
      expect(page).to have_content('外部のAIサービス（例: OpenAI, Inc. 等）のAPIを利用しています。')

      # お問い合わせ先の確認
      expect(page).to have_content('describe.this.contact@gmail.com')

      # 最終更新日の記載
      expect(page).to have_content('最終更新日：2026年8月2日')
    end
  end
end
