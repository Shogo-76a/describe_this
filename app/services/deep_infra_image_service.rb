class DeepInfraImageService
  @@client = nil

  def self.client
    @@client ||= OpenAI::Client.new(
      access_token: Rails.application.credentials.deepinfra.api_key,
      uri_base: "https://api.deepinfra.com/v1/openai"
    )
  end

  def self.generate(prompt)
    response = client.images.generate(
      parameters: {
        model: "black-forest-labs/FLUX-1-schnell", # モデルIDを正確に指定
        prompt: prompt,
        size: "512x348",
        response_format: "b64_json", # DeepInfraは現在 b64_json のみをサポート
        num_inference_steps: 3 # ステップ数を限界まで下げる (schnellは1〜4で動作可能)
      }
    )
    # Base64文字列を抽出（これはデコードではない）
    response.dig("data", 0, "b64_json")
  rescue => e
    Rails.logger.error "DeepInfra API Error: #{e.message}"
    raise
  end
end