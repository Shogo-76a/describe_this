class GenerateImageJob < ApplicationJob
  queue_as :default

  def perform(game, language)
    Rails.logger.info "ジョブが実行されました: #{game}"

    # gptへの指示（プロンプト）を作成する。今回はJSON形式での出力を厳密に指示する。
    prompt = <<-PROMPT
    「#{game.description}」という説明を#{language}ネイティブとして理解してください。
    説明文にあること以外は脚色せず、説明から受ける印象だけを頼りに画像生成API「FLUX.1 Schnell」へ指示を記述してください。
    記述方法は下記[Subject + Setting + Lighting] 構文を参考にしてください。

    A macro photo of a single rain droplet on a neon-green leaf, sunset light reflecting inside the water, sharp focus, cinematic bokeh.

    以下のJSON形式で、キーや値の型も完全に守って応答してください。
    {
        "Subject": "A single rain droplet",
        "Setting": "On a neon-green leaf",
        "Lighting": "Sunset light reflecting inside the water",
        "instructions": "A macro photo of a single rain droplet on a neon-green leaf, sunset light reflecting inside the water, sharp focus, cinematic bokeh."
    }

    PROMPT

    # OpenAI APIクライアントを初期化する
    client = OpenAI::Client.new

    # APIにリクエストを送信する。JSONモードを有効にする。
    request_gpt = client.chat(
    parameters: {
        model: "gpt-4o-mini",
        messages: [ { role: "user", content: prompt } ],
        response_format: { type: "json_object" },
        # temperature: 応答のランダム性（創造性）を制御。0に近いほど決定的で、2に近いほど多様な応答。
        # 0.7は、ある程度の創造性を保ちつつ、安定した応答を得やすい一般的な値。
        temperature: 0.7
    }
    )

    # AIからのJSON応答をパースし、インスタンス変数に格納する
    raw_response_gpt = request_gpt.dig("choices", 0, "message", "content")
    response_gpt = JSON.parse(raw_response_gpt)


    # Base64文字列を抽出
    base64_string = DeepInfraImageService.generate(response_gpt["instructions"])

    # 文字列を元の画像データ（バイナリ）に変換
    decoded_data = Base64.decode64(base64_string)

    # Railsがファイルとして扱えるように StringIO に包む
    io = StringIO.new(decoded_data)

    # Active Storage にアタッチする
    game.generated_image.attach(
    io: io,
    filename: "describethisimage_#{Time.current.to_i}.png",
    content_type: "image/png"
    )
  end
end
