class GamesController < ApplicationController
  def top
  end

  def new
    @game = Game.new
    render "games/start"
  end

  def create
  end

  def update
  end

  def show
    # プロフィールページ
    # MVP では仮ページを表示
    # 本リリース ではユーザーテーブルからユーザーIDを渡す
  end

private
  def game_params
    params.require(:game).permit(:generated_image)
  end
end
