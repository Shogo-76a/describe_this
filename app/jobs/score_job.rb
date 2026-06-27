

class ScoreJob < ApplicationJob
  queue_as :default
  require 'openai'
  require 'base64'
    
  # ジョブが失敗した際のリトライ回数を指定（Solid Queueが自動で管理）
  retry_on ActiveRecord::Deadlocked, wait: 3.seconds, attempts: 2

  def perform(game, language)
    Rails.logger.info "採点 のジョブが実行されました: #{game}"
    # 画像ファイルを読み込んでBase64に変換
    # File.read の代わりに URI.open を使用して、インターネット上の画像データを直接読み込む
    base64_theme_image = Base64.strict_encode64(URI.open(game.theme_image_url).read)
    base64_generated_image = Base64.strict_encode64(URI.open(game.generated_image.url).read)

    # gptへの指示（プロンプト）を作成する。今回はJSON形式での出力を厳密に指示する。
    system_prompt = <<-PROMPT
    You are the referee for an image whispering game (Telephone game). 
    Your task is to strictly evaluate the intuitive and atmospheric similarity between two provided images (Image A: Original Prompt, Image B: Player's Answer) and score it out of 100.

    Evaluate the similarity based comprehensively on these three aspects:
    1. Subject Matter: Is the core motif/object successfully conveyed?
    2. Composition: Are the layout, angles, and placement of elements aligned?
    3. Color & Mood: Do the color palette and overall atmosphere match?

    # Scoring Guidelines
    - 90-100: Flawless transition. The core motif, composition, and mood are highly recognizable at a glance.
    - 70-89: The core motif is clearly conveyed, but there are minor creative liberties or shifts in composition/color.
    - 40-69: The intent is visible, but the composition, colors, or style have significantly changed or become abstract.
    - 10-39: Barely any common ground between the two images.
    - 0: Completely unrelated images.

    # Output Format
    You must output ONLY a valid JSON object. Do not include any conversational filler, markdown formatting (except the JSON itself), or extra text outside the JSON.

    {
    "overall": (integer between 0 and 100),
    "details":["concept": (integer between 0 and 100), "color": (integer between 0 and 100), "composition": (integer between 0 and 100)],
    "reason": "(A very short, one-sentence explanation in #{language} highlighting why this score was given, mentioning key similarities or differences.)"
    }
    PROMPT

    # OpenAI APIクライアントを初期化する
    client = OpenAI::Client.new

    # APIにリクエストを送信する。JSONモードを有効にする。
    request_gpt = client.chat(
    parameters: {
        model: "gpt-4o-mini",
        messages: [
        { role: "system", content: system_prompt },
        {
            role: "user",
            content: [
            { type: "text", text: "Please evaluate these two images based on the system instructions." },
            # 画像A（お題）
            {
                type: "image_url",
                image_url: { url: "data:image/jpeg;base64,#{base64_theme_image}" }
            },
            # 画像B（ユーザーの回答）
            {
                type: "image_url",
                image_url: { url: "data:image/jpeg;base64,#{base64_generated_image}" }
            }
            ]
        }
        ],
        response_format: { type: "json_object" },
        # temperature: 応答のランダム性（創造性）を制御。0に近いほど決定的で、2に近いほど多様な応答。
        temperature: 0.2
    }
    )

    # AIからのJSON応答をパースし、インスタンス変数に格納する
    raw_response_gpt = request_gpt.dig("choices", 0, "message", "content")
    response_gpt = JSON.parse(raw_response_gpt)


    puts response_gpt["overall"]

    # update! で安全に実行。失敗したときに例外を発生する。
    game.update!(score: response_gpt)

  rescue ActiveRecord::RecordNotFound => e
    # レコードが削除されていた場合は、リトライせずにログを残して終了
    Rails.logger.warn("Job skipped: #{game} not found. #{e.message}")
  end
end