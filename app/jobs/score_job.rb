

class ScoreJob < ApplicationJob
  queue_as :default
  require "openai"
  require "base64"

  # ジョブが失敗した際のリトライ回数を指定（Solid Queueが自動で管理）
  retry_on ActiveRecord::Deadlocked, wait: 3.seconds, attempts: 2

  def perform(game, explanation_lang, target_lang)
    Rails.logger.info "採点 のジョブが実行されました: #{game}"
    # 画像ファイルを読み込んでBase64に変換
    # File.read の代わりに URI.open を使用して、インターネット上の画像データを直接読み込む
    base64_theme_image = Base64.strict_encode64(URI.open(game.theme_image_url).read)
    base64_generated_image = Base64.strict_encode64(game.generated_image.download)

    # gptへの指示（プロンプト）を作成する。今回はJSON形式での出力を厳密に指示する。
    system_prompt = <<-PROMPT
    # Role & Context
    Act as a warm, supportive #{target_lang} coach for intermediate learners (aged 10+, CEFR B1-B2). Review the user's description by comparing the "Theme Image" (お題) and the "AI's Image". Frame your advice around helping the user convey a more specific and clear image to the other party (the AI) to perfectly match the Theme Image. Always address the user directly ("you") in #{explanation_lang} for explanations/praise, and use natural #{target_lang} for corrections/examples.

    # Scoring Criteria (0-100)
    Assess how accurately and vividly the text communicated the details of the Theme Image to recreate it as the AI's Image.
    - 90-100: Flawless communication of the image.
    - 70-89: Clear motif, minor details or color shifts.
    - 40-69: Visible intent, but the core image didn't fully come across.
    - 10-39: Barely any common ground.
    - 0: Completely unrelated.

    # Rules
    1. Focus ONLY on 1-2 critical language errors in "key_points". Do not nitpick.
    2. Identify up to 5 spelling errors. If none, return an empty array `[]`.

    # Output Format
    Output ONLY a valid JSON object. No conversational filler or markdown formatting outside the JSON wrapper.
    {
      "overall": (integer, 0-100 based on scoring criteria),
      "image_analysis": "Explain in #{explanation_lang} how well the description conveyed the image to the other party. Include what was successfully communicated, what didn't quite come across, and specific tips/phrases to convey a more specific image to the AI next time. [CRUCIAL: If score >= 70 and text is natural, you MUST start with '十分にイメージの伝達ができていますので、これ以上の修正は必要ないかもしれませんが、'. If score < 40, NEVER use this disclaimer; explain why the main image failed to come across in the AI's Image].",
      
      "praise": "Encouraging comment in #{explanation_lang}. If score >= 40: Praise how effectively the text conveyed a vivid image to the other party, resulting in a great AI's Image. If score < 40: Praise the user's attempt and encourage a fresh start on communicating the Theme Image's core subject. NEVER praise the visual result if score < 40.",
      
      "original_text": "The exact text provided by the user.",
      "rewritten_text": "A natural, native-level #{target_lang} version of the user's text. It MUST be phrased as a natural, fluid 'description of the image' (colloquial or literary is fine) that perfectly paints a clear picture for the listener.",
      
      "spelling_errors": [
        {
          "error": "Misspelled word",
          "correction": "Correct spelling"
        }
      ],
      
      "key_points": [
        {
          "point": "Short title of advice in #{explanation_lang}.",
          "explanation": "Concise explanation (1-2 sentences) in #{explanation_lang}. [CRUCIAL: If score >= 70 and text is natural, you MUST start with '十分にイメージの伝達ができていますので、これ以上の修正は必要ないかもしれませんが、'. Otherwise, NEVER use it]."
        }
      ],
      
      "bonus_phrase": {
        "phrase": "One useful idiom/collocation/phrasal verb in #{target_lang} related to the topic.",
        "meaning": "Meaning explained in #{explanation_lang}.",
        "example": "Short example sentence in #{target_lang} using the phrase.",
        "example_translation": "The exact translation of the example sentence written in #{explanation_lang}."
      }
    }
    PROMPT

    # OpenAI APIクライアントを初期化する
    client = OpenAI::Client.new

    # APIにリクエストを送信する。JSONモードを有効にする。
    request_gpt = client.chat(
    parameters: {
        Theme: "gpt-4o-mini",
        messages: [
        { role: "system", content: system_prompt },
        {
            role: "user",
            content: [
            {type: "text", text: "Please evaluate this explanation '#{game.description}' as the original_text based on the system instructions."},
            { type: "text", text: "Please evaluate these two images based on the system instructions. By the way, Image A is the Theme and Image B is the AI's Image." },
            # お題のイメージ
            {
                type: "image_url",
                image_url: { url: "data:image/jpeg;base64,#{base64_theme_image}" }
            },
            # AIのイメージ
            {
                type: "image_url",
                image_url: { url: "data:image/jpeg;base64,#{base64_generated_image}" }
            }
            ]
        }
        ],
        response_format: { type: "json_object" },
        # temperature: 応答のランダム性（創造性）を制御。0に近いほど決定的で、2に近いほど多様な応答。
        temperature: 0.5
    }
    )

    # AIからのJSON応答をパースし、インスタンス変数に格納する
    raw_response_gpt = request_gpt.dig("choices", 0, "message", "content")
    response_gpt = JSON.parse(raw_response_gpt)

    # update! で安全に実行。失敗したときに例外を発生する。
    game.update!(score: response_gpt)


    # テスト環境ではブロードキャストをスキップ。反映できない。
    unless Rails.env.test?
      Turbo::StreamsChannel.broadcast_update_to(
        "resulting_score_#{game.id}",
        target: "resulting_score",
        partial: "shared/resulting_score",
        locals: { game: game }
      )

      sleep 1 # フロント側の読み込み完了を待つ
      # カスタムStreamアクションを直接送出する
      Turbo::StreamsChannel.broadcast_action_to(
        "submission_#{game.id}",
        action: :update_gauge,
        attributes: { value: game.score["overall"] }
      )
    end
  rescue ActiveRecord::RecordNotFound => e
    # レコードが削除されていた場合は、リトライせずにログを残して終了
    Rails.logger.warn("Job skipped: #{game} not found. #{e.message}")
  end
end
