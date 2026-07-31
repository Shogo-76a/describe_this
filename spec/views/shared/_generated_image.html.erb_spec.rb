require 'rails_helper'

RSpec.describe 'shared/_generated_image', type: :view do
  context '画像がアタッチされていない場合' do
    let(:game) { create(:game, generated_image: nil) } # または Build された game インスタンス

    it 'プレースホルダー用のdiv要素が表示されること' do
      render partial: 'shared/generated_image', locals: { game: game }

      # img タグが表示されていないことを確認
      expect(rendered).not_to have_selector('img')

      # else 側の placeholder div が表示されていることを確認
      expect(rendered).to have_selector('div.bg-base-100')
    end
  end
end
