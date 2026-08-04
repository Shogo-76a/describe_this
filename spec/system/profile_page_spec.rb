require 'rails_helper'

RSpec.describe 'プロフィールページ', type: :system do
  it 'プロフィールページの要素が すべて 表示される' do
    visit user_path(9999) # MVP用仮プロフィールページのパス
    page.refresh # 導入画面をスキップする
    expect(page).to have_content("利用規約")
    expect(page).to have_content("プライバシーポリシー")
    expect(page).to have_content("お問い合わせ")
  end
end
