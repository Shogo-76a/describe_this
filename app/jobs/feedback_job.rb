

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
    Assess how accurately and vividly the text communicated the details of the Model Image to recreate it as the AI's Image.
    - 90-100: Flawless communication of the image.
    - 70-89: Clear motif, minor details or color shifts.
    - 40-69: Visible intent, but the core image didn't fully come across.
    - 10-39: Barely any common ground.
    - 0: Completely unrelated.

    # Rules
    1. Instead of nitpicking minor grammar, provide one clear, actionable takeaway in "next_step_advice" based on the overall feedback to help the user describe images better next time.
    2. You will receive an array of user descriptions (up to 3). You MUST process them individually and generate exactly one object in the "proposals" array for each provided description.

    # Output Format
    Output ONLY a valid JSON object. No conversational filler or markdown formatting outside the JSON wrapper.
    {
      "overall": (integer, 0-100 based on scoring criteria),
      "image_analysis": "Explain in #{explanation_lang} how well the descriptions conveyed the image to the other party. Include what was successfully communicated, what didn't quite come across, and specific tips/phrases to convey a more specific image to the AI next time. [CRUCIAL: If score < 40, NEVER use this disclaimer; explain why the main image failed to come across in the AI's Image].",
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
    Rails.logger.info "array_user_messagesの中身！！！: #{array_user_messages}"

    # 文字列に変換して、書式を複数の説明文が箇条書きとしてAIに理解させる。
    user_messages = array_user_messages.map.with_index(1) do |desc, i|
      "Description #{i}: #{desc}"
    end.join("\n")

    Rails.logger.info "user_messagesの中身！！！: #{user_messages}"

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
