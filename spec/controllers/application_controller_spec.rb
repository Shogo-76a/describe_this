require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe 'environment conditions' do
    context 'production環境の初期化時' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it 'allow_browser の定義行が実行されること' do
        # production 環境の条件分岐を通過させるためにクラス定義ファイルを再ロード
        expect {
          load Rails.root.join('app/controllers/application_controller.rb')
        }.not_to raise_error
      end
    end
  end
end