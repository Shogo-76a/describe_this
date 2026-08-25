class GamesController < ApplicationController
  # @game = Game.find(params[:id]) をまとめてます。
  before_action :set_game, only: %i[show update check_generated_image check_score score feedback destroy]

  # @message_limit = 3 をまとめてます。
  before_action :set_message_limit, only: %i[new show]

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
    # ユーザーのメッセージ送信回数。check_generated_imageアクションで画面更新する要素を分岐する
    @game.message_seq += 1

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

    image_success = params[:image_success].to_i

    # 1. 画像が添付されていない場合は 204 を返して終了
    unless @game.generated_image.attached?
      return head :no_content
    end

    if @game.message_seq.present?
      if @game.message_seq <= @game.image_seq
        if image_success < 1
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
          render turbo_stream: [
            turbo_stream.update(
              "generated-image",
              partial: "shared/generated_image",
              locals: { game: @game }
            ),

            turbo_stream.update(
              "scoring_button",
              partial: "shared/scoring_button",
              locals: { game: @game }
            )
          ]
        end
      else
        head :no_content
      end
    else
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
  # 該当のゲームテーブル取得
  def set_game
    @game = Game.find(params[:id])
  end

  # メッセージ送信可能回数
  def set_message_limit
    @message_limit = 3
  end

  def game_params
    params.require(:game).permit(:description, :generated_image, :theme_image_url)
  end
end
