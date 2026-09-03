class GameUpdater
  def initialize(game, params)
    @game = game
    @params = params
  end

  # returns [success, errors, system_reply]
  def call
    if @game.update(@params)

      language = TextSelectorOnLocale.call_no_i18n(@game.locale_in_game)

      # enqueue job
      GenerateImageJob.perform_later(@game, language)
      system_reply = GameForm.new(feedback:  I18n.t("services.game_updater.system_message_1"))
      [ true, nil, system_reply ]

    else
      [ false, @game.errors, nil ]
    end
  end
end
