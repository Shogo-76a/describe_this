require 'rails_helper'

RSpec.describe DeepInfraImageService, type: :service do
  describe '.generate メソッド' do
    let(:prompt) { 'a beautiful cat' }
    let(:mock_client) { instance_double(OpenAI::Client) }
    let(:mock_images) { double('images') }

    before do
      # DeepInfraImageService.client が疑似クライアントを返すように設定
      allow(described_class).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:images).and_return(mock_images)
    end

    context '正常に画像が生成された場合' do
      let(:response) do
        {
          'data' => [
            { 'b64_json' => 'sample_base64_string' }
          ]
        }
      end

      before do
        allow(mock_images).to receive(:generate).and_return(response)
      end

      it 'Base64文字列を返すこと' do
        result = described_class.generate(prompt)
        expect(result).to eq('sample_base64_string')
      end
    end

    context 'API呼び出しでエラーが発生した場合' do
      let(:error_message) { 'API Key is invalid' }

      before do
        # generate メソッド呼び出し時に例外を発生させる
        allow(mock_images).to receive(:generate).and_raise(StandardError.new(error_message))
      end

      it 'エラーログを出力し、例外を再発生(raise)させること' do
        # Rails.logger.error が意図したメッセージで呼ばれることを確認
        expect(Rails.logger).to receive(:error).with("DeepInfra API Error: #{error_message}")

        # 例外が再発生（raise）されることを確認
        expect {
          described_class.generate(prompt)
        }.to raise_error(StandardError, error_message)
      end
    end
  end
end