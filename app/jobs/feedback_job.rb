

class FeedbackJob < ApplicationJob
  queue_as :default
  require "openai"
  require "base64"

  # ジョブが失敗した際のリトライ回数を指定（Solid Queueが自動で管理）
  retry_on ActiveRecord::Deadlocked, wait: 3.seconds, attempts: 2

  def perform(game, target_lang, explanation_lang)
    Rails.logger.info "採点 のジョブが実行されました: #{game}"
    # 画像ファイルを読み込んでBase64に変換
    # File.read の代わりに URI.open を使用して、インターネット上の画像データを直接読み込む
    base64_theme_image = Base64.strict_encode64(URI.open(game.theme_image_url).read)
    base64_generated_image = Base64.strict_encode64(game.generated_image.download)

    # gptへの指示（プロンプト）を作成する。今回はJSON形式での出力を厳密に指示する。
    system_prompt = <<-PROMPT
    # Role & Context
    Act as a warm, supportive #{target_lang} coach for intermediate learners (aged 10+, CEFR B1-B2). Review the user's descriptions by comparing the "Model Image" (お題) and the "AI's Image". Frame your advice around helping the user convey a more specific and clear image to the other party (the AI) to perfectly match the Model Image. Always address the user directly ("you") in #{explanation_lang} for explanations/praise, and use natural #{target_lang} for corrections/examples.
    # Scoring Criteria (0-100)
    Assess how accurately and vividly the text communicated the details of the Model Image to recreate it as the AI's Image. Use these highly granular tiers:
    - 95-100: Flawless. Perfect recreation of subject, setting, actions, lighting, and mood.
    - 90-94: Near-Perfect. Core is exact; only minute details (e.g., a tiny background prop) differ.
    - 85-89: Excellent. Highly accurate; minor color shifts or slight spatial relationship differences.
    - 80-84: Very Good. Strong match; missing 1-2 secondary elements (e.g., specific clothing, time of day).
    - 75-79: Good. Main subject is highly accurate; background or atmosphere is slightly generic.
    - 70-74: Fairly Good. Core motif is clear; noticeable details are omitted or simplified.
    - 65-69: Satisfactory. Visible intent; a major element (either setting or specific action) is incorrect.
    - 60-64: Moderate. Subject is broadly recognizable; context and secondary subjects are heavily shifted.
    - 50-59: Halfway. About 50% alignment (e.g., correct setting but completely wrong subject, or vice versa).
    - 40-49: Weak. 1-2 main keywords conveyed; the overall visual structure and intent are lost.
    - 30-39: Poor. Vague conceptual link only; visually feels like a completely different scene.
    - 20-29: Very Poor. Barely any common ground; only a broad category matches (e.g., just "an outdoor scene").
    - 10-19: Minimal. A single minor trait or color matches by chance; otherwise entirely unrelated.
    - 1-9: Negligible. Almost totally disjointed; virtually no semantic overlap.
    - 0: Completely Unrelated. 0% match.
    # Rules
    1. Instead of nitpicking minor grammar, provide one clear, actionable takeaway in "next_step_advice" based on the overall feedback to help the user describe images better next time.
    2. You will receive an array of user descriptions (up to 3). You MUST process them individually and generate exactly one object in the "proposals" array for each provided description.
    # Output Format
    Output ONLY a valid JSON object. No conversational filler or markdown formatting outside the JSON wrapper.
    {
      "title_for_history": "A short, atmospheric, and stylish title (1-4 words) in #{target_lang} based on the user's description. Make it sound like a music album or track title—poetic, evocative, and cinematic (e.g., '朝の静けさと水色の湖' or 'Silent Waters at Dawn' instead of 'カヌーに乗る女性').",
      "overall": (integer, 0-100 based on scoring criteria),
      "image_analysis": "Evaluate in #{explanation_lang} how well the descriptions conveyed the image. Include successes, missing details, and specific tips. [CRUCIAL: Use `\\n\\n` to separate logical paragraphs (Overall, Successes, Tips). If score < 40, skip disclaimers and strictly explain why the core image failed.]",
      "proposals": [
        {
          "original_text": "One of the exact texts provided by the user from the input array.",
          "rewritten_text": "An upgraded #{target_lang} version of the original_text. [CRUCIAL ALGORITHM: 1. Preserve the user's original intent. 2. Keep the overall phrasing as simple as possible while accurately describing the Model Image. 3. You MUST incorporate exactly one natural or useful phrase/idiom into this sentence to improve it.]",
          "bonus_phrase": {
            "phrase": "The exact natural or useful phrase/idiom that you introduced in the 'rewritten_text' above.",
            "meaning": "Meaning explained in #{explanation_lang}.",
            "example": "A short, practical example sentence in #{target_lang} using this phrase.",
            "example_translation": "The exact translation of the example sentence written in #{explanation_lang}."
          }
        }
      ]
    }
    PROMPT

    # OpenAI APIクライアントを初期化する
    client = OpenAI::Client.new

    # game.context配列から ユーザーのメッセージを抽出した配列を作る。
    array_user_messages = game.array_context.select.with_index { |_, index| index.even? }

    # 文字列に変換して、書式を複数の説明文が箇条書きとしてAIに理解させる。
    user_messages = array_user_messages.map.with_index(1) do |desc, i|
      "Description #{i}: #{desc}"
    end.join("\n")


    # APIにリクエストを送信する。JSONモードを有効にする。
    request_gpt = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          {
              role: "user",
              content: [
              {
                type: "text",
                text: "Here are the descriptions the user tried:\n#{user_messages}\n\nPlease evaluate them based on the system instructions."
              },
              # 1つ目の画像のアナウンス
              {
                  type: "text",
                  text: "Below is the 'Model Image' (お題) referenced in the system instructions:"
              },
              # お題のイメージ
              {
                  type: "image_url",
                  image_url: { url: "data:image/jpeg;base64,#{base64_theme_image}" }
              },
              # 2つ目の画像のアナウンス
              {
                  type: "text",
                  text: "Below is the 'AI's Image' (AI画像) referenced in the system instructions:"
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
        temperature: 0.2
      }
    )

    # AIからのJSON応答をパースし、インスタンス変数に格納する
    raw_response_gpt = request_gpt.dig("choices", 0, "message", "content")
    response_gpt = JSON.parse(raw_response_gpt)

    # update! で安全に実行。失敗したときに例外を発生する。
    game.update!(feedback: response_gpt)

  rescue ActiveRecord::RecordNotFound => e
    # レコードが削除されていた場合は、リトライせずにログを残して終了
    Rails.logger.warn("Job skipped: #{game} not found. #{e.message}")
  end
end
