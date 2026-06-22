class GamesController < ApplicationController
  def top
  end

  def new
    # ここでお題画像のseed値を決定。themeに代入#
    theme = SecureRandom.uuid
    image_url = "https://picsum.photos/seed/#{theme}/800/600"
    @game = Game.new(theme_image_url: image_url)
    render "games/start"
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
