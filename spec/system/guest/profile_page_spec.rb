require 'rails_helper'

RSpec.describe 'ゲスト', type: :system do
  it 'プロフィールページの要素が すべて 表示される' do
    visit guest_user_path(0)
    page.refresh # 導入画面をスキップする
    expect(page).to have_content("利用規約")
    expect(page).to have_content("プライバシーポリシー")
  end
end
