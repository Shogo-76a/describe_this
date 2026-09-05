class TranscribeService
  class Error < StandardError; end
  class ValidationError < Error; end
  class OpenAIError < Error; end

  def initialize(audio_file:, prompt: nil, language: nil, client: nil, model: "whisper-1", temperature: 0.0)
    @audio_file = audio_file
    @prompt = prompt
    @language = language
    @model = model
    @client = client || OpenAI::Client.new
    @temperature = temperature
  end

  # 実行して文字列を返す。失敗時は例外を投げる。
  def call
    validate!

    response = @client.audio.transcribe(
      parameters: {
        model: @model,
        file: @audio_file.tempfile,
        prompt: @prompt,
        temperature: @temperature
      }
    )

    if response.is_a?(Hash) && response["error"]
      # OpenAI API のエラーをラップして投げる
      raise OpenAIError, response["error"]["message"]
    end


    # Whisper-1のハルシネーション定型文を確認。あれば削除して、空を返す。
    striped_response = (response["text"] || "").strip
    hallucinations = [
      /\Athank\s?you[\.!\?]?\z/i,                     # "Thank you." "thank you" "thank you!"
      /\Athank\s?you\sfor\swatching[\.!\?]?\z/i,      # "Thank you for watching." "Thank you for watching!"
      /\Athanks?\sfor\swatching[\.!\?]?\z/i,          # "Thanks for watching." "Thanks for watching!"
      /\Ayou[\.!\?]?\z/i,                             # "You." "You"
      /subtitles\sby\samara\.org/i,              # 字幕サイトのハルシネーション（これだけは部分一致でも安全）
      /\AI'm going to try to make this as clear as I possibly can[\.!\?]?\z/i # "I'm going to try to make this as clear as I possibly can."
    ]

    if striped_response.blank? || hallucinations.any? { |regexp| striped_response.match?(regexp) } # regexp(正規表現)
      # 無音・ノイズとして処理し、何も出力しない
      ""
    else
      # ハルシネーションではない場合にデータを返す。
      striped_response
    end


  rescue OpenAIError
    raise
  rescue => e
    # 想定外のエラーもサービスエラーとしてラップ
    raise Error, e.message
  end

  private

  def validate!
    if @audio_file.nil?
      raise ValidationError, "音声ファイルが見つかりません"
    end

    unless @audio_file.respond_to?(:tempfile)
      raise ValidationError, "無効なファイルオブジェクトです"
    end
  end
end
