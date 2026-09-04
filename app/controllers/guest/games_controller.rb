module Guest
  class GamesController < Guest::BaseController
    # @game = Game.find(params[:id]) をまとめてます。
    before_action :set_game, only: %i[show update check_generated_image check_score score feedback destroy]

    # @message_limit = 3 をまとめてます。
    before_action :set_message_limit, only: %i[new show]

    def top; end

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
      @game.locale_in_game = cookies[:job_param].to_s

      if @game.save
        redirect_to guest_game_path(@game)
      else
        render :new, status: :unprocessable_entity
        Rails.logger.info "Gameレコードの作成に失敗しました。"
      end
    end

    def show
      @message_limit = 1 # メッセージ送信回数
    end

    def update

      # 翻訳サポートありなしの分岐の中継メソッド（currentモデルにmodeとallowed_languagesの値を渡す）
      set_mode_context(@game)

      updater = GameUpdater.new(@game, game_params)
      success, errors, system_reply = updater.call

      if success
        respond_to do |format|
          format.turbo_stream do
            @system_reply = system_reply
          end
        end
      else
        @message_limit = 1 # メッセージ送信回数　ゲストは1回だけの送信なので、送信失敗したら残り回数は1回のまま。
        
        # 修正ポイント：エラー時もTurbo Streamを使ってフォーム部分だけを更新する
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "chat_form_wrapper", # フォームを囲んでいる要素のID（ビューに合わせて変更してください）
              partial: "shared/guest_chat_form_wrapper", # フォーム部分のパーシャル名
              locals: { game: @game, message_limit: @message_limit }
            )
          end
          # JavaScriptが無効な環境や直接アクセスされた場合のフォールバック
          format.html { render :show, status: :unprocessable_entity }
        end
      end
    end

    def check_generated_image
      @system_reply = GameForm.new(feedback: t(".system_message_1"))
      image_success = params[:image_success].to_i

      if @game.generated_image.attached?
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
              locals: { message: @system_reply }
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
      in_game_lang = TextSelectorOnLocale.call(@game.locale_in_game)
      out_game_lang = TextSelectorOnLocale.call(cookies[:locale] || I18n.default_locale)
      # 採点のJobを実行
      Guest::ScoringJob.perform_later(@game, in_game_lang, out_game_lang) # 引数（レコード, 学習言語, 説明言語）
    end

    def feedback
      # サンプル表示用
      @game.feedback.merge!("bonus_phrase" => {
        "phrase" => "sample sample sample",
        "example" => "sample sample samplesample sample samplesample sample sample.",
        "meaning" => "sample sample sample",
        "example_translation" => "sample sample samplesample sample sample" },
        "original_text" => "sample sample samplesample sample samplesample sample samplesample sample sample",
        "image_analysis" => "sample sample samplesample sample samplesample sample sample",
        "rewritten_text" => "sample sample samplesample sample sample",
        "spelling_errors" => [ "error" =>"samplesample", "correction" =>"sample" ],
        "next_step_advice" => "sample sample samplesamplesample sample samplesample")
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

    # メッセージ送信可能回数。ゲストモードは 1回に設定。
    def set_message_limit
      @message_limit = 1
    end

    def game_params
      params.require(:game).permit(:description, :generated_image, :theme_image_url, :locale_in_game)
    end

    def set_mode_context(game)
      # cookieから現在のゲームモードを取得（なければ 0 翻訳サポートあり）
      mode = cookies[:mode].to_i || 0
      Current.mode = mode

      # モードに応じて、許可する言語を柔軟に切り替える
      Current.allowed_languages = case mode
                                  when 0
                                    nil # nil の場合はバリデーションをスキップする目印にする
                                  when 2
                                    [game.locale_in_game] # 'en' などが入る 
                                  else
                                    nil # デフォルト
                                  end
    end

  end
end
