class GamesController < ApplicationController
  before_action :set_game, only: %i[show update check_generated_image check_score score feedback destroy]
  allow_unauthenticated_access only: %i[top]
  def top
    if Current.user.present?
      @user = Current.user
    else
      redirect_to guest_root_path
    end
  end

  def new
    if params[:image_url].present?
      @game = Game.new(theme_image_url: params[:image_url])
    else
      picker = ThemeImagePicker.new
      image_url = picker.call
      @game = Game.new(theme_image_url: image_url)
    end
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      redirect_to @game
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def update
    updater = GameUpdater.new(@game, game_params)
    success, errors, system_replies = updater.call

    if success
      respond_to do |format|
        format.turbo_stream do
          @system_replies = system_replies
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def check_generated_image
    @system_replies = GameForm.new(feedback: "分かった！こんな感じかな！")

    # クライアント側（Stimulus）から送られた基準時刻(sinceパラメータ)がある場合、それ以降に添付された画像だけを有効とする
    since_time = if params[:since].present?
      begin
        Time.zone.parse(params[:since]) # params[:since] をサーバー側の Time オブジェクトに変換
      rescue
        nil
      end
    end

    if @game.generated_image.attached?
      if since_time.present?
        attachment_time = @game.generated_image.attachment.created_at
        if attachment_time >= since_time  # attachment_timeの方が古い 又は 同じ場合に 新しい画像と判断 -> turbo_stream を返す（200）
          render turbo_stream: [
            turbo_stream.update(
              "generated-image",
              partial: "shared/generated_image",
              locals: { game: @game }
            ),

            turbo_stream.append(
              "chat_messages_container",
              partial: "shared/message",
              locals: { message: @system_replies }
            ),

            turbo_stream.update(
              "scoring_button",
              partial: "shared/scoring_button",
              locals: { game: @game }
            )
          ]
        else
          head :no_content
        end
      else
        # since パラメータがない場合は従来通り添付の有無だけで判定
        render turbo_stream: [
          turbo_stream.update(
            "generated-image",
            partial: "shared/generated_image",
            locals: { game: @game }
          ),

          turbo_stream.append(
            "chat_messages_container",
            partial: "shared/message",
            locals: { message: @system_replies }
          ),

          turbo_stream.update(
            "scoring_button",
            partial: "shared/scoring_button",
            locals: { game: @game }
          )
        ]
      end
    else
      # まだレコードがない場合は「204 No Content」を返し、Stimulus側に継続させる
      head :no_content
    end
  end


  def check_score
    if @game.feedback.present?
      render turbo_stream: turbo_stream.update(
          "resulting_score",
          partial: "shared/resulting_score",
          locals: { game: @game }
        )
    else
      # まだレコードがない場合は「204 No Content」を返し、Stimulus側に継続させる
      head :no_content
    end
  end

  def score
    # 採点のJobを実行
    FeedbackJob.perform_later(@game, "English", "Japanese") # 引数（レコード, 学習言語, 説明言語）
  end

  def feedback
  end

  def destroy
    @game.destroy

    redirect_to root_path, status: :see_other
  end

private
  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:description, :generated_image, :theme_image_url)
  end
end
