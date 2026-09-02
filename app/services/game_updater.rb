class GameUpdater
  def initialize(game, params)
    @game = game
    @params = params
  end

  # returns [success, errors, system_reply]
  def call
    if @game.update(@params)
      # enqueue job
      GenerateImageJob.perform_later(@game, "English")
      system_reply = GameForm.new(feedback:  I18n.t(".system_message_1"))
      [ true, nil, system_reply ]

    else
      [ false, @game.errors, nil ]
    end
  end
end
