require 'rails_helper'

RSpec.describe "管理画面(Avo)", type: :system do
  context "Games データテーブル", js: true do
    let!(:game_dummy) { create(:game) }
    before do
      visit "/avo/resources/games"
    end
    
    it "テーブル 一覧が 表示される" do
      expect(page).to have_content("Games")
    end

    it "Bulk Destroy メソッドが ページ上で正常に動作する" do
      first('input[type="checkbox"]', visible: :all).click
      click_button 'Actions'
      find_link('Bulk Destroy').click
      expect(page).not_to have_content("td")
    end
  end
end