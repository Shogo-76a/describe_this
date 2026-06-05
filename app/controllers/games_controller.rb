class GamesController < ApplicationController
  def top
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      redirect_to @game, notice: "保存しました" # リダイレクト先にインスタンス@game を入れると、game_path(@game)とRailsが解釈。よって、show アクションが実行される。
    else
      # status: :unprocessable_entity が必須！
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @game = Game.find(params[:id])
  end

  def tutorial_step
    case params[:step].to_i
    when 1 then render partial: "shared/splash_modal/modal_01"
    when 2 then render partial: "shared/splash_modal/modal_02"
    when 3 then render partial: "shared/splash_modal/modal_03"
    else
      head :bad_request
    end
  end

private
  def game_params
    params.require(:game).permit(:generated_image)
  end
end
