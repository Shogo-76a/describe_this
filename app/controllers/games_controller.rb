class GamesController < ApplicationController
  include Authentication
  # @game = Game.find(params[:id]) をまとめてます。
  before_action :set_game, only: %i[show update check_generated_image check_score score feedback destroy]

  # @message_limit = 3 をまとめてます。
  before_action :set_message_limit, only: %i[new show]

  def index

    # ワード検索
    @query = params[:query]
    if @query.present?

      # 全角・半角スペースで文字列を分割し、空の要素を除外
      keywords = @query.split(/[[:space:]]+/).reject(&:blank?)

      # 初期スコープを current_user.games に設定
      @games = current_user.games

      # 分割した単語ごとにループを回して、AND条件（.where）を重ねていく
      keywords.each do |keyword|
        escaped_keyword = ".*#{Regexp.escape(keyword)}.*"

        # 各単語ごとのPostgreSQL条件（テキスト用）
        sql_conditions = [
          "jsonb_path_exists(feedback, :phrase_path) OR 
          jsonb_path_exists(feedback, :example_path) OR 
          jsonb_path_exists(feedback, :meaning_path) OR 
          jsonb_path_exists(feedback, :trans_path) OR 
          jsonb_path_exists(feedback, :original_path) OR 
          jsonb_path_exists(feedback, :rewritten_path)"
        ]

        query_params = {
          phrase_path:  "$.proposals[*].bonus_phrase.phrase ? (@ like_regex \"#{escaped_keyword}\" flag \"i\")",
          example_path: "$.proposals[*].bonus_phrase.example ? (@ like_regex \"#{escaped_keyword}\" flag \"i\")",
          meaning_path: "$.proposals[*].bonus_phrase.meaning ? (@ like_regex \"#{escaped_keyword}\" flag \"i\")",
          trans_path:   "$.proposals[*].bonus_phrase.example_translation ? (@ like_regex \"#{escaped_keyword}\" flag \"i\")",
          original_path:    "$.proposals[*].original_text ? (@ like_regex \"#{escaped_keyword}\" flag \"i\")",
          rewritten_path:  "$.proposals[*].rewritten_text ? (@ like_regex \"#{escaped_keyword}\" flag \"i\")"
        }

        # 単語が数字（整数）の場合は数値検索条件を AND で追加
        if keyword.match?(/\A\d+\z/) # 文章やフレーズの中に単語が含まれているか？という条件。
          sql_conditions << "(feedback ->> 'overall')::integer = :score" # overall の点数が :score と一致するか？」という条件をsql_conditions配列に追加します。
          query_params[:score] = keyword.to_i # 検索された数値をintegerに変換してquery_paramsハッシュに追加します。
        end

        # ループ全体として「すべての単語にマッチすること (.where の連続による AND検索)」を実行
        # where検索にかけると同時に、sql_conditionsのキーワードに query_paramsの対応する値を結合する。
        @games = @games.where(sql_conditions.join(" OR "), query_params).order(created_at: :desc).includes([:generated_image_attachment])

        # 検索分の基本形。参考に。
        # @posts = Post.where("title LIKE ?", "%#{@query}%")
      end
    else
      @games = current_user.games.all.order(created_at: :desc).includes([:generated_image_attachment])
    end
  end

  def new
    if params[:image_url].present?
      @game = current_user.games.build(theme_image_url: params[:image_url])
    else
      picker = ThemeImagePicker.new
      image_url = picker.call
      @game = current_user.games.build(theme_image_url: image_url)
    end
  end

  def create
    @game = current_user.games.build(game_params)

    if @game.save
      redirect_to user_game_path(current_user, @game)
    else
      render :new, status: :unprocessable_entity
      Rails.logger.info "Gameレコードの作成に失敗しました。"
    end
  end

  def show; end

  def update
    # ユーザーのメッセージ送信回数。check_generated_imageアクションで画面更新する要素を分岐する
    @game.message_seq += 1

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

    # 1. 画像が添付されていない場合は 204 を返して終了
    unless @game.generated_image.attached?
      return head :no_content
    end

    if @game.message_seq.present?
      if @game.message_seq <= @game.image_seq
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
        head :no_content
      end
    else
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
    if params[:history_mode].present? # 履歴ページからの遷移を判定する
      @history_mode = params[:history_mode].to_i
    else
      @history_mode = 0
      # 採点のJobを実行
      FeedbackJob.perform_later(@game, "English", "Japanese") # 引数（レコード, 学習言語, 説明言語）
    end
  end

  def feedback
    if params[:history_mode].present? # 履歴ページからの遷移を判定する
      @history_mode = params[:history_mode].to_i
    else
      @history_mode = 0
    end
  end

  def destroy
    @game.destroy

    redirect_to top_user_path(current_user), status: :see_other
  end

private
  # 該当のゲームテーブル取得
  def set_game
    @game = current_user.games.find(params[:id])
  end

  # メッセージ送信可能回数
  def set_message_limit
    @message_limit = 3
  end

  def game_params
    params.require(:game).permit(:description, :generated_image, :theme_image_url)
  end


  def current_user
    Current.session&.user
  end
  helper_method :current_user

end
