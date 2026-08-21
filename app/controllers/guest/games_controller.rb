module Guest
  class GamesController < Guest::BaseController
    before_action :set_game, only: %i[show update check_generated_image check_score score feedback destroy]

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

      if @game.save
        redirect_to guest_game_path(@game)
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
              locals: { message: @system_replies }
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
      # 採点のJobを実行
      GuestScoringJob.perform_later(@game, "English", "Japanese") # 引数（レコード, 学習言語, 説明言語）
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

      redirect_to guest_root_path, status: :see_other
    end

  private
    def set_game
      @game = Game.find(params[:id])
    end

    def game_params
      params.require(:game).permit(:description, :generated_image, :theme_image_url)
    end
  end
end
