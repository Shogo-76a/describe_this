class TranscriptionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  def new
    # 録音画面を表示するだけ
  end

  def create
    audio_file = params[:audio]

    # 1. 音声ファイルの存在チェック
    if audio_file.nil?
      render json: { error: "音声ファイルが見つかりません" }, status: :bad_request
      return
    end

    # 2. ruby-openai のクライアント初期化
    # (config/initializers/openai.rb等でAPIキーが設定されている前提)
    client = OpenAI::Client.new

    # 3. whisper-1 による文字起こし処理
    # whisper-1 は優秀なため、RailsのTempfileをそのまま渡すだけで動作します
    response = client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: audio_file.tempfile,
        language: "ja",
        prompt: "不要な『えーと』や『あの』などのケバ取りを行い、自然な日本語に修正してください。"
      }
    )

    # 4. エラーハンドリングとレスポンスの返却
    if response["error"]
      logger.error "======== OpenAI API ERROR ========"
      logger.error response["error"]["message"]
      render json: { error: "文字起こしに失敗しました: #{response['error']['message']}" }, status: :internal_server_error
    else
      render json: { text: response["text"] }
    end

  rescue => e
    logger.error "======== SYSTEM ERROR ========"
    logger.error e.message
    logger.error e.backtrace.join("\n")
    render json: { error: "システムエラーが発生しました: #{e.message}" }, status: :internal_server_error
  end
end