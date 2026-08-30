class TranscribeService
  class Error < StandardError; end
  class ValidationError < Error; end
  class OpenAIError < Error; end

  DEFAULT_MODEL = "whisper-1".freeze
  DEFAULT_LANGUAGE = "ja".freeze

  def initialize(audio_file:, prompt: nil, language: DEFAULT_LANGUAGE, client: nil, model: DEFAULT_MODEL)
    @audio_file = audio_file
    @prompt = prompt
    @language = language
    @model = model
    @client = client || OpenAI::Client.new
  end

  # 実行して文字列を返す。失敗時は例外を投げる。
  def call
    validate!

    response = @client.audio.transcribe(
      parameters: {
        model: @model,
        file: @audio_file.tempfile,
        language: @language,
        prompt: @prompt
      }
    )

    if response.is_a?(Hash) && response["error"]
      # OpenAI API のエラーをラップして投げる
      raise OpenAIError, response["error"]["message"]
    end

    # 正常系: API が返す text を返す
    # ※ ruby-openai の返却フォーマットに合わせて必要なら調整してください
    response.fetch("text")
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