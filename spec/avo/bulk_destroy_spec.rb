require 'rails_helper'

RSpec.describe Avo::Actions::BulkDestroy do
  let(:action) { described_class.new }

  describe 'BulkDestroyの handle メソッド動作確認' do
    let!(:game1) { create(:game) } # プロジェクトのモデルに合わせて調整してください
    let!(:game2) { create(:game) }
    let(:query) { Game.where(id: [game1.id, game2.id]) }

    context '正常に削除できる場合' do
      it 'レコードを削除すること' do
        expect {
          action.handle(query: query)
        }.to change(Game, :count).by(-2)
      end
    end

    context '例外が発生した場合' do
      before do
        allow_any_instance_of(Game).to receive(:destroy!).and_raise(StandardError.new("エラー"))
      end

      it 'rescue 節が実行され、fail メソッドが呼ばれること' do
        # receive メソッドなどで fail の呼出しを検証
        expect(action).to receive(:fail).with(/Failed to delete/)
        action.handle(query: query)
      end
    end
  end
end