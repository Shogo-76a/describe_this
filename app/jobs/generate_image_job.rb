class GenerateImageJob < ApplicationJob
  queue_as :default

  def perform(game, language)
    Rails.logger.info "ジョブが実行されました: #{game}"

    # gptへの指示（プロンプト）を作成する。今回はJSON形式での出力を厳密に指示する。
    prompt = <<-PROMPT
    Read the user's description "#{game.description}" as a #{language} native speaker, and create an English image generation prompt for the "FLUX.1 Schnell" API.

    Following a 4-stage psychological and cognitive linguistic process of image elaboration, apply "appropriate and natural elaboration" while keeping the user's exact words as the main focus.

    [The 4-Stage Elaboration Rules]
    1. Literal: You must rigidly include all specific elements (nouns, verbs, adjectives) explicitly stated in the description and place them at the center of the image.
    2. Experiential: Fill in the natural, implicit details required for the situation to realistically exist (e.g., if it's a person, add clothes/hair; if it's an object, add texture or placement).
    3. Associative: Supplement the scene with an associated natural background (setting), time of day, lighting, and atmosphere. If no setting is specified by the user, provide a natural, generic background.
    4. Artistic (SUPPRESS): Unless explicitly stated by the user, do NOT add excessive metaphors, surreal art styles, or extreme compositions. Maintain a clean, high-resolution, photorealistic style.

    Use the [Subject + Setting + Lighting] syntax below as a reference for your description:
    Example: A macro photo of a single rain droplet on a neon-green leaf, sunset light reflecting inside the water, sharp focus, cinematic bokeh.

    Respond STRICTLY in the following JSON format, keeping the exact keys and value types:

    {
        "Subject": "The main subject including [Literal] and [Experiential] elements (e.g., A single rain droplet)",
        "Setting": "The background or location supplemented by [Associative] elaboration (e.g., On a neon-green leaf)",
        "Lighting": "The lighting or time of day supplemented by [Associative] elaboration (e.g., Sunset light reflecting inside the water)",
        "instructions": "The final prompt for FLUX.1 Schnell combining the Subject, Setting, and Lighting above into a single, natural English sentence."
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
