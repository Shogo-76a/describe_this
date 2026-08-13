class GamesController < ApplicationController
  before_action :set_game, only: %i[show update check_generated_image check_score score feedback destroy]

  def top
    @user = Current.user
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

    if @game.generated_image.attached?
      # 配列に入れて、1回の render turbo_stream: でまとめて返却する
      render turbo_stream: [
        # 画像プレースホルダーを置き換える (id="generated-image" の要素を置換)
        turbo_stream.replace(
          "generated-image",
          partial: "shared/generated_image",
          locals: { game: @game }
        ),

        # チャットコンテナの末尾にメッセージを追加 (id="chat_messages_container" の末尾に追加)
        turbo_stream.append(
          "chat_messages_container",
          partial: "shared/message",
          locals: { message: @system_replies }
        ),

        # 採点ボタンを更新して有効化 (id="scoring_button" の中身を更新)
        # ※ game を @game に修正しています
        turbo_stream.update(
          "scoring_button",
          partial: "shared/scoring_button",
          locals: { game: @game }
        )
      ]
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
