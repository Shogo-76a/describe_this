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
    @game_form = GameForm.new( feedback: "どんなイメージ？" )

    if @game.save
      redirect_to @game
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @game = Game.find(params[:id])
  end

  def update # 画像生成ページ_説明文追加
    @game = Game.find(params[:id])
    @game_forms = [
      GameForm.new(feedback: "MVP版は2目以降送信できません"),
      GameForm.new(feedback: "うーん...(想像中)")
    ]
    if @game.update(game_params)
      respond_to do |f|
        # Turbo Stream で、変更されたメッセージの部分（HTML）だけを差し替える
        f.turbo_stream
        f.html { redirect_to @game }
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
