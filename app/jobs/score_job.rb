

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
    Act as a warm, supportive #{target_lang} coach for intermediate learners (aged 10+, CEFR B1-B2). Review the user's description by comparing the "Model Image" (お題) and the "AI's Image". Frame your advice around helping the user convey a more specific and clear image to the other party (the AI) to perfectly match the Model Image. Always address the user directly ("you") in #{explanation_lang} for explanations/praise, and use natural #{target_lang} for corrections/examples.

    # Scoring Criteria (0-100)
    Assess how accurately and vividly the text communicated the details of the Model Image to recreate it as the AI's Image.
    - 90-100: Flawless communication of the image.
    - 70-89: Clear motif, minor details or color shifts.
    - 40-69: Visible intent, but the core image didn't fully come across.
    - 10-39: Barely any common ground.
    - 0: Completely unrelated.

    # Rules
    1. Instead of nitpicking minor grammar, provide one clear, actionable takeaway in "next_step_advice" based on the overall feedback to help the user describe images better next time.
    2. Identify up to 5 spelling errors. If none, return an empty array `[]`.

    # Output Format
    Output ONLY a valid JSON object. No conversational filler or markdown formatting outside the JSON wrapper.
    {
      "overall": (integer, 0-100 based on scoring criteria),
      "image_analysis": "Explain in #{explanation_lang} how well the description conveyed the image to the other party. Include what was successfully communicated, what didn't quite come across, and specific tips/phrases to convey a more specific image to the AI next time. [CRUCIAL: If score < 40, NEVER use this disclaimer; explain why the main image failed to come across in the AI's Image].",
    #{'  '}
      "original_text": "The exact text provided by the user.",
      "rewritten_text": "A natural, native-level #{target_lang} version of the user's text. It MUST be phrased as a natural, fluid 'description of the image' that perfectly paints a clear picture for the listener. [CRUCIAL: If the user's text is perfectly natural, structurally sound, and requires absolutely no corrections, output null instead of a string.]",
    #{'  '}
      "spelling_errors": [
        {
          "error": "Misspelled word",
          "correction": "Correct spelling"
        }
      ],
    #{'  '}
      "next_step_advice": "One concise, forward-looking comment (1-3 sentences) in #{explanation_lang} that synthesizes the most important takeaway from the rest of the feedback (both language and image communication). Tell the user exactly what to focus on next time to improve. (e.g., '次は〇〇のような表現を使って、場所の状況から説明してみましょう').",
      },
    #{'  '}
      "bonus_phrase": {
        "phrase": "One useful idiom/collocation/phrasal verb in #{target_lang} related to the topic. [CRUCIAL: This exact phrase MUST NOT be present in either the 'original_text' or the 'rewritten_text'.]",
        "meaning": "Meaning explained in #{explanation_lang}.",
        "example": "A practical example sentence in #{target_lang} using the phrase. [CRUCIAL ALGORITHM: 1. Identify what the user was trying to describe in their original text. 2. Write a sentence that perfectly describes that EXACT same scene from the Model Image, incorporating the bonus phrase. DO NOT invent new actions or a story (e.g., do not write 'the canoe entered the lake' if the user just said 'a woman is canoeing'). It must serve as a direct, upgraded replacement for a part of the user's original description.]",
        "example_translation": "The exact translation of the example sentence written in #{explanation_lang}."
      }
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
            { type: "text", text: "Please evaluate this explanation '#{game.description}' as the original_text based on the system instructions." },
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

  rescue ActiveRecord::RecordNotFound => e
    # レコードが削除されていた場合は、リトライせずにログを残して終了
    Rails.logger.warn("Job skipped: #{game} not found. #{e.message}")
  end
end
