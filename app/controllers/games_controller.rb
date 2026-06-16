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
          GameForm.new(feedback: "どんなイメージか教えてください"),
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
          @system_replies = [
            GameForm.new(feedback: "MVP版は2目以降送信できません"),
            GameForm.new(feedback: "うーん...(想像中)")
          ]
          # 自動的に app/views/games/update.turbo_stream.erb が呼ばれます
        end
      end
    else
      respond_to do |f|
        # バリデーションエラーなどの場合
        f.html { render @game, status: :unprocessable_entity }
      end
    end
      
  end

private
  def game_params
    params.require(:game).permit(:description, :generated_image, :theme_image_url)
  end
end