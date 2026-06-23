class GamesController < ApplicationController
  def top
  end


  def new
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
        image_url = "default_placeholder.png"
      end

    rescue => e
      # Cloudinaryでエラーが起きたときの処理
      Rails.logger.error "Cloudinary Error: #{e.message}"

      # Active Storageの仕組みやローカルのassets画像に逃がす
      image_url = "default_placeholder.png"
    end

    @game = Game.new(theme_image_url: image_url)
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
    respond_to do |format|
      format.html
      format.turbo_stream do
        # 表示したいテキストの配列をインスタンス変数にセット
        @system_replies = [
          GameForm.new(feedback: "どんなイメージか教えてください")
        ]
        # 自動的に app/views/games/show.turbo_stream.erb が呼ばれます
      end
    end
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
          GenerateImageJob.perform_later(@game, "日本語")
        end
      end
    else
      # 失敗した時は、newではなく現在のチャット画面（show）のデータを再準備して返す
      # これにより、MissingTemplate エラーが消えます
      # @system_replies = [GameForm.new(feedback: "空欄でござる。")] # 必要に応じて空の配列などを定義
      render :show, status: :unprocessable_entity
    end
  end

  def score
    @game = Game.find(params[:id])
  end

  def feedback
  end

  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    redirect_to new_game_path, status: :see_other
  end

private
  def game_params
    params.require(:game).permit(:description, :generated_image, :theme_image_url)
  end
end
