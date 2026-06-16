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
      # 通常のブラウザアクセス時：画面をそのまま表示
      format.html 

      # Stimulusからの裏側リクエスト時：自動メッセージを配信
      format.turbo_stream do
        render turbo_stream: render_system_message("どんなイメージかな？")
      end
    end
  end

  def update
    @game = Game.find(params[:id])
    # ユーザーメッセージの保存処理（例: @user_message = ... ）
    if @game.update(game_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # ユーザーのメッセージを右側(chat-end)に追加                           
            turbo_stream.append("chat_messages_container", partial: "shared/message", locals: { message: @game }),
            # アプリ側の応答メッセージを左側(chat-start)に追加（共通メソッドの使い回し）
            render_system_message("MVP版は2目以降送信できません"),
            render_system_message("うーん...(想像中)")
          ]
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



  # アプリ側メッセージを生成してTurbo Stream形式で返す
  def render_system_message(text)
    system_message = Game.new(feedback: text)
    
    turbo_stream.append(
      "chat_messages_container",
      partial: "shared/message",
      locals: { message: system_message }   
    )
  end

end