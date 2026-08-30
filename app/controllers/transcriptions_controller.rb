class TranscriptionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    # 録音画面を表示するだけ
  end

  def create
    audio_file = params[:audio]

    service = TranscribeService.new(
      audio_file: audio_file,
      prompt: "不要な『えーと』や『あの』などのケバ取りを行い、自然な日本語に修正してください。",
      language: "ja"
    )

    text = service.call
    render json: { text: text }
  rescue TranscribeService::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  rescue TranscribeService::OpenAIError => e
    render json: { error: "文字起こしに失敗しました: #{e.message}" }, status: :internal_server_error
  rescue TranscribeService::Error => e
    render json: { error: "音声処理中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
  rescue => e
    render json: { error: "システムエラーが発生しました: #{e.message}" }, status: :internal_server_error
  end
end