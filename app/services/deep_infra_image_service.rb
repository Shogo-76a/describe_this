class DeepInfraImageService
    def self.client
        # 環境変数 ENV を使用するのが標準的です
        OpenAI::Client.new(
        access_token: Rails.application.credentials.deepinfra.api_key,
        uri_base: "https://api.deepinfra.com/v1/openai"
        )
    end

    def self.generate(prompt)
        response = client.images.generate(
        parameters: {
            model: "black-forest-labs/FLUX-1-schnell", # モデルIDを正確に指定
            prompt: prompt,
            size: "1024x768",
            response_format: "b64_json" # DeepInfraは現在 b64_json のみをサポート
            }
        )    

        # Base64文字列を抽出（これはデコードではない）
        response.dig("data", 0, "b64_json")
    end
end