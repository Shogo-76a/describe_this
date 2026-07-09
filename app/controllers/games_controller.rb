class GamesController < ApplicationController
  def top
  end


  def new
    if params[:image_url].present?
      @game = Game.new(theme_image_url: params[:image_url])
    else
      # ここでお題画像のseed値を決定
      current_seed = SecureRandom.uuid
      seed_integer = current_seed.hash

      begin
        # Cloudinaryから画像リストを取得
        images = CloudinaryFolderService.fetch_images_from_folder("describe_this/theme_images")

        if images.any?
          random_generator = Random.new(seed_integer)
          selected_id = images.sample(random: random_generator)

          # cl_image_tagの代わりに、通常のimage_tagで使えるCloudinaryのURLを生成
          image_url = Cloudinary::Utils.cloudinary_url(
                        selected_id,
                        width: 600, height: 400, crop: :fill, fetch_format: :auto, quality: :auto
                      )
        else
          # フォルダが空だった場合のフォールバック（assets内のデフォルト画像）
          image_url = "placeholder_gray.png"
        end

      rescue => e
        # Cloudinaryでエラーが起きたときの処理
        Rails.logger.error "Cloudinary Error: #{e.message}"

        # Active Storageの仕組みやローカルのassets画像に逃がす
        image_url = "placeholder_white.png"
      end

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

  def show
    @game = Game.find(params[:id])
  end

  def update
    @game = Game.find(params[:id])
    # ユーザーメッセージの保存処理（例: @user_message = ...）
    if @game.update(game_params)
      respond_to do |format|
        format.turbo_stream do
          # 返答したいテキストの配列をインスタンス変数にセット
          # 自動的に app/views/games/update.turbo_stream.erb が呼ばれます
          @system_replies = [
            GameForm.new(feedback: "MVP版は2回目以降送信できません"),
            GameForm.new(feedback: "うーん...(想像中)")
          ]

          # 画像生成のJobを実行
          GenerateImageJob.perform_later(@game, "English") # 引数（レコード, 学習言語）
        end
      end
    else
      # 失敗した時は、newではなく現在のチャット画面（show）のデータを再準備して返す
      render :show, status: :unprocessable_entity
    end
  end

  def check_generated_image
    @game = Game.find(params[:id])
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
    @game = Game.find(params[:id])

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
    @game = Game.find(params[:id])
    # 採点のJobを実行
    FeedbackJob.perform_later(@game, "English", "Japanese") # 引数（レコード, 学習言語, 説明言語）
  end

  def feedback
    @game = Game.find(params[:id])
  end

  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    redirect_to root_path, status: :see_other
  end

private
  def game_params
    params.require(:game).permit(:description, :generated_image, :theme_image_url)
  end
end
