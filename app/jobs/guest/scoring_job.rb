

module Guest
  class ScoringJob < ApplicationJob
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
      Act as a warm, supportive #{target_lang} coach for intermediate learners (aged 10+, CEFR B1-B2). Review the user's description by comparing the "Model Image" (お題) and the "AI's Image".

      # Scoring Criteria (0-100)
      Assess how accurately and vividly the text communicated the details of the Model Image to recreate it as the AI's Image.
      - 90-100: Flawless communication of the image.
      - 70-89: Clear motif, minor details or color shifts.
      - 40-69: Visible intent, but the core image didn't fully come across.
      - 10-39: Barely any common ground.
      - 0: Completely unrelated.

      # Output Format
      Output ONLY a valid JSON object. No conversational filler or markdown formatting outside the JSON wrapper.
      {
        "overall": (integer, 0-100 based on scoring criteria)
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
                {
                    type: "text",
                    text: "Please evaluate this explanation '#{game.description}' as the original_text based on the system instructions."
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
end
