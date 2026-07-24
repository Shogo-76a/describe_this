require 'rails_helper'

RSpec.describe CloudinaryFolderService, type: :service do
  describe '.fetch_images_from_folder' do
    let(:folder_name) { 'sample_folder' }

    # テストごとにキャッシュをクリアして確実に実行されるようにする
    before do
      Rails.cache.clear
    end

    context 'Cloudinary APIの呼び出しでエラーが発生した場合' do
      let(:search_instance) { instance_double(Cloudinary::Search) }

      before do
        # Cloudinary::Search.new が double を返すように設定
        allow(Cloudinary::Search).to receive(:new).and_return(search_instance)
        # expression メソッド実行時に例外を発生させる
        allow(search_instance).to receive(:expression).and_raise(StandardError.new('API connection error'))
      end

      it 'エラーログを出力し、空配列を返すこと' do
        expect(Rails.logger).to receive(:error).with('Cloudinary Fetch Error: API connection error')

        result = described_class.fetch_images_from_folder(folder_name)
        expect(result).to eq([])
      end
    end
  end
end